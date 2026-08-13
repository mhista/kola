// inbound_media_service.dart — a customer's photo, from webhook to CDN.
//
// ── THE SECOND INGESTION PATH ────────────────────────────────────────
//
// The dashboard uploads straight from the browser with a signed token
// (ImageKitService.createUploadAuth). That path cannot serve an inbound
// WhatsApp or Telegram photo, because there is no browser anywhere in
// that story: the bytes are announced to a webhook on this server.
//
// So there are two paths and one destination:
//
//   owner, in the dashboard   browser ──signed──▶ ImageKit
//   customer, on WhatsApp     Meta ──▶ kola ──▶ ImageKit
//   customer, on Telegram     Telegram ──▶ kola ──▶ ImageKit
//
// Both end as an ImageKit URL, which is what makes the dashboard able to
// render either one with the same <img src>. The Operations screen does
// not need to know how a picture arrived.
//
// ── NEITHER PROVIDER SENDS THE FILE ──────────────────────────────────
//
// Both send a REFERENCE, and resolving it needs that channel's own
// credentials — which is why this cannot be a signed browser upload and
// why ImageKit cannot fetch the URL itself:
//
//   Telegram   webhook gives file_id → getFile → file_path → download
//              from api.telegram.org/file/bot<TOKEN>/<path>.
//              That URL EMBEDS THE BOT TOKEN. Handing it to ImageKit
//              would hand a third party the credential that can read and
//              send every message for that business.
//
//   WhatsApp   webhook gives a media id → GET /<id> → a short-lived url
//              → download it WITH an Authorization: Bearer header.
//              ImageKit cannot supply that header, so a remote-fetch
//              would simply fail. The URL also expires in minutes.
//
// Downloading here and re-uploading is therefore not a detour, it is the
// only correct shape.
//
// ── FAILURE NEVER LOSES THE MESSAGE ──────────────────────────────────
//
// Every method returns null instead of throwing. A customer asking "do
// you have this?" with a photo has sent a real message that must be
// stored and routed whether or not the picture reaches the CDN — see
// message.spy.yaml on why mediaKind set with mediaUrl null is a
// deliberate, meaningful pairing rather than an inconsistency.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/media/imagekit_service.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/kola_logger.dart';

/// A file that arrived from a customer and now lives on ImageKit.
class InboundMedia {
  const InboundMedia({
    required this.kind,
    required this.url,
    this.thumbnailUrl,
    this.imagekitFileId,
    this.mimeType,
  });

  final String kind;
  final String url;
  final String? thumbnailUrl;
  final String? imagekitFileId;
  final String? mimeType;
}

class InboundMediaService {
  InboundMediaService(this._imagekit);

  final ImageKitService _imagekit;

  /// Anything larger is not stored.
  ///
  /// WhatsApp caps images at 5MB and video at 16MB, so this is not a
  /// restriction an ordinary customer will meet — it is a bound on what
  /// a hostile or malfunctioning sender can make this server buffer in
  /// memory, since the download happens before anything is streamed
  /// anywhere.
  static const maxBytes = 20 * 1024 * 1024;

  // ── Telegram ───────────────────────────────────────────────────────

  /// Resolves a Telegram `file_id` and stores it.
  ///
  /// Two hops, because Telegram's webhook never includes a path: getFile
  /// turns the id into a file_path, and only then can the bytes be
  /// fetched.
  Future<InboundMedia?> fromTelegram({
    required Channel channel,
    required int workspaceId,
    required String fileId,
    required String kind,
    String? mimeType,
  }) async {
    final token = _credentialOf(channel);
    if (token == null) return null;

    try {
      final meta = await http.get(Uri.parse(
        'https://api.telegram.org/bot$token/getFile?file_id=$fileId',
      ));
      if (meta.statusCode != 200) {
        Log.warning('Telegram getFile failed',
            data: {'status': meta.statusCode});
        return null;
      }

      final decoded = jsonDecode(meta.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;
      final path = result?['file_path'] as String?;
      if (path == null) return null;

      // The token is in this URL. It is used here and never stored,
      // never logged, and never handed to ImageKit.
      final bytes = await _download(
        Uri.parse('https://api.telegram.org/file/bot$token/$path'),
      );
      if (bytes == null) return null;

      return _store(
        bytes: bytes,
        workspaceId: workspaceId,
        fileName: _nameFrom(path, kind),
        kind: kind,
        mimeType: mimeType,
      );
    } catch (e) {
      Log.warning('Telegram media fetch threw', data: {'error': '$e'});
      return null;
    }
  }

  // ── WhatsApp ───────────────────────────────────────────────────────

  /// Resolves a WhatsApp Cloud API media id and stores it.
  ///
  /// Also two hops: the id resolves to a short-lived URL, and that URL
  /// still requires the bearer token to actually download — a detail
  /// that catches people out, because the URL looks public.
  Future<InboundMedia?> fromWhatsApp({
    required Channel channel,
    required int workspaceId,
    required String mediaId,
    required String kind,
    String? mimeType,
  }) async {
    final credential = _credentialOf(channel);
    if (credential == null) return null;

    // WhatsApp channels store several values; the access token is what
    // this needs. Stored as JSON by ChannelEndpoint, with a bare token
    // as the older shape — both are accepted rather than assuming.
    final token = _whatsappAccessToken(credential);
    if (token == null) return null;

    try {
      final meta = await http.get(
        Uri.parse('https://graph.facebook.com/v21.0/$mediaId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (meta.statusCode != 200) {
        Log.warning('WhatsApp media lookup failed',
            data: {'status': meta.statusCode});
        return null;
      }

      final decoded = jsonDecode(meta.body) as Map<String, dynamic>;
      final url = decoded['url'] as String?;
      if (url == null) return null;

      final bytes = await _download(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (bytes == null) return null;

      return _store(
        bytes: bytes,
        workspaceId: workspaceId,
        fileName: '$mediaId${_extensionFor(mimeType, kind)}',
        kind: kind,
        mimeType: mimeType ?? decoded['mime_type'] as String?,
      );
    } catch (e) {
      Log.warning('WhatsApp media fetch threw', data: {'error': '$e'});
      return null;
    }
  }

  // ── Shared ─────────────────────────────────────────────────────────

  Future<InboundMedia?> _store({
    required Uint8List bytes,
    required int workspaceId,
    required String fileName,
    required String kind,
    String? mimeType,
  }) async {
    final uploaded = await _imagekit.uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: ImageKitService.inboundFolderFor(workspaceId),
      // Tagged so inbound customer media can be found, audited or purged
      // as a group without touching the business's own product shots.
      tags: 'inbound,customer',
    );
    if (uploaded == null) return null;

    return InboundMedia(
      kind: kind,
      url: uploaded.url,
      thumbnailUrl: uploaded.thumbnailUrl,
      imagekitFileId: uploaded.fileId,
      mimeType: mimeType,
    );
  }

  Future<Uint8List?> _download(Uri uri, {Map<String, String>? headers}) async {
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      Log.warning('Media download failed', data: {'status': response.statusCode});
      return null;
    }
    if (response.bodyBytes.length > maxBytes) {
      Log.warning('Media exceeded the size limit',
          data: {'bytes': response.bodyBytes.length});
      return null;
    }
    return response.bodyBytes;
  }

  /// Decrypts the channel's stored credential.
  ///
  /// Returns null rather than throwing on a channel with none — a
  /// half-configured channel should degrade to "no picture", not take
  /// down the message handler.
  String? _credentialOf(Channel channel) {
    final encrypted = channel.encryptedCredential;
    if (encrypted == null || encrypted.isEmpty) return null;
    try {
      return ChannelCredentialEncryptionService.decrypt(encrypted);
    } catch (e) {
      Log.warning('Could not decrypt channel credential',
          data: {'channelId': channel.id});
      return null;
    }
  }

  /// WhatsApp credentials are stored as JSON (appId, wabaId,
  /// phoneNumberId, accessToken, verifyToken). Falls back to treating
  /// the whole string as the token, which is the shape older rows use.
  String? _whatsappAccessToken(String credential) {
    final trimmed = credential.trim();
    if (!trimmed.startsWith('{')) return trimmed.isEmpty ? null : trimmed;
    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      final token = json['accessToken'] as String?;
      return (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      return null;
    }
  }

  String _nameFrom(String path, String kind) {
    final last = path.split('/').last;
    return last.isEmpty ? '$kind-${DateTime.now().millisecondsSinceEpoch}' : last;
  }

  /// A filename with no extension makes ImageKit guess, and a guess that
  /// lands on the wrong type breaks rendering in the dashboard.
  String _extensionFor(String? mimeType, String kind) {
    return switch (mimeType) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/webp' => '.webp',
      'video/mp4' => '.mp4',
      'audio/ogg' => '.ogg',
      'application/pdf' => '.pdf',
      _ => kind == 'image' ? '.jpg' : '',
    };
  }
}
