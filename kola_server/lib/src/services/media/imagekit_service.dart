// imagekit_service.dart — signed uploads and deletes for product media.
//
// ── HOW THIS DIFFERS FROM asami's ImageKitService, AND WHY ────────────
//
// asami_server uploads the file ITSELF: dio FormData, MultipartFile
// .fromFile, straight to ImageKit. That is exactly right there, because
// asami's client is a Flutter app holding a real File on a real
// filesystem.
//
// kola_dashboard is a browser. Copying that shape would mean base64-ing
// every photo into a Serverpod endpoint parameter — Serverpod params are
// JSON, so a 5MB image becomes ~6.7MB of string, crosses the wire twice
// (browser→kola→ImageKit), and arrives as one opaque request with no way
// to report progress beyond "sending". On a Lagos mobile connection that
// is the difference between a progress bar and a frozen screen.
//
// So this server does the ONE thing that genuinely requires the private
// key, and nothing else:
//
//   getUploadAuth()  → {token, expire, signature}
//   the browser POSTs the file straight to upload.imagekit.io
//   saveProductMedia() records what came back
//
// The private key never leaves this process. The file never touches it.
//
// ── THE SIGNATURE ────────────────────────────────────────────────────
//
// ImageKit's browser flow is documented as:
//
//   signature = HMAC-SHA1( token + expire , privateKey )   hex encoded
//
// `token` is any unique string per upload; `expire` is a Unix timestamp
// in seconds, and ImageKit rejects anything more than an hour ahead.
// Both are echoed back in the upload request so ImageKit can recompute
// the HMAC and compare.
//
// SHA-1 here is not a security judgement I get to make — it is what the
// upload API verifies against. It is a MAC over two values the server
// chose seconds ago, not a password hash, and the short expiry is what
// bounds the damage of a leaked signature.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/kola_logger.dart';

/// What the browser needs to upload one file.
class ImageKitUploadAuth {
  const ImageKitUploadAuth({
    required this.token,
    required this.expire,
    required this.signature,
    required this.publicKey,
  });

  final String token;
  final int expire;
  final String signature;

  /// Sent so the dashboard never has to carry a copy of it. The public
  /// key is public by design — it identifies the ImageKit account, it
  /// does not authorise anything on its own.
  final String publicKey;

  Map<String, dynamic> toJson() => {
        'token': token,
        'expire': expire,
        'signature': signature,
        'publicKey': publicKey,
      };
}

class ImageKitService {
  ImageKitService();

  static final _random = Random.secure();

  /// How long a signature stays usable.
  ///
  /// Ten minutes, against ImageKit's one-hour ceiling. Long enough for a
  /// large video on a slow connection, short enough that a signature
  /// captured from a browser's network log is worthless by the time
  /// anyone finds it. Each upload gets its own.
  static const _validity = Duration(minutes: 10);

  bool get isConfigured =>
      Env.imagekitPrivateKey.isNotEmpty && Env.imagekitPublicKey.isNotEmpty;

  /// One-shot credentials for a single browser upload.
  ImageKitUploadAuth createUploadAuth() {
    final token = _token();
    final expire =
        (DateTime.now().toUtc().add(_validity).millisecondsSinceEpoch ~/ 1000);

    final hmac = Hmac(sha1, utf8.encode(Env.imagekitPrivateKey));
    final signature = hmac.convert(utf8.encode('$token$expire')).toString();

    return ImageKitUploadAuth(
      token: token,
      expire: expire,
      signature: signature,
      publicKey: Env.imagekitPublicKey,
    );
  }

  /// Removes a file from ImageKit.
  ///
  /// Runs HERE and not in the browser, because deletion is the one media
  /// operation that needs the private key directly — there is no signed
  /// client-side delete. A browser that could delete would be a browser
  /// that could delete anything in the account.
  ///
  /// Returns false rather than throwing when the file is already gone.
  /// A caller removing a photo wants the row deleted either way, and a
  /// 404 from ImageKit means the desired end state already holds.
  Future<bool> deleteFile(String fileId) async {
    if (!isConfigured) return false;

    final credentials =
        base64Encode(utf8.encode('${Env.imagekitPrivateKey}:'));

    try {
      final response = await http.delete(
        Uri.parse('https://api.imagekit.io/v1/files/$fileId'),
        headers: {'Authorization': 'Basic $credentials'},
      );

      // 204 is success. 404 means it is already absent, which is the
      // same outcome from the caller's point of view.
      if (response.statusCode == 204 || response.statusCode == 404) {
        return true;
      }

      Log.warning(
        'ImageKit delete failed',
        data: {'fileId': fileId, 'status': response.statusCode},
      );
      return false;
    } catch (e) {
      // Deliberately swallowed and logged. A CDN being unreachable must
      // not stop an owner removing a photo from their own catalog — the
      // row goes, and the orphan is a cost problem to reconcile, not a
      // reason to block the person.
      Log.warning('ImageKit delete threw', data: {'fileId': fileId, 'error': '$e'});
      return false;
    }
  }

  /// The folder a workspace's media lives in.
  ///
  /// Scoped per workspace so one business's uploads are never mixed with
  /// another's in the ImageKit dashboard, and so a whole tenant can be
  /// removed by folder if it ever has to be.
  static String folderFor(int workspaceId) => '/kola/workspaces/$workspaceId';

  /// 32 hex characters from a CSPRNG.
  ///
  /// Uniqueness is all ImageKit needs — the token only has to differ
  /// per upload so one signature cannot be replayed for another file.
  /// Random.secure() rather than a timestamp or a counter, because two
  /// uploads started in the same millisecond would collide.
  static String _token() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ── The OTHER ingestion path: server-side upload ────────────────────
  //
  // createUploadAuth above serves the DASHBOARD, where a browser holds
  // the file. It cannot serve an inbound WhatsApp or Telegram photo,
  // because there is no browser in that story at all — the bytes arrive
  // at a webhook on this server and never go near one.
  //
  // ── AND ImageKit CANNOT JUST FETCH THE URL ITSELF ───────────────────
  //
  // ImageKit accepts a remote URL in place of a file, which looks like
  // the obvious shortcut. It is wrong for both providers:
  //
  //   Telegram  the download URL embeds the bot token
  //             (api.telegram.org/file/bot<TOKEN>/<path>). Handing that
  //             to ImageKit hands a third party the credential that can
  //             read and send every message for that business.
  //
  //   WhatsApp  the media URL needs an Authorization: Bearer header and
  //             expires in minutes. ImageKit cannot supply the header,
  //             so the fetch would simply fail.
  //
  // So this path downloads with the workspace's own credentials and
  // uploads the bytes. Server-side upload authenticates with the private
  // key over Basic auth — no signature, because a signature exists to
  // let an UNTRUSTED client upload without holding the key, and this
  // process holds it.

  /// Uploads bytes already in hand. Used for inbound customer media.
  ///
  /// Returns null rather than throwing: a customer's photo failing to
  /// reach the CDN must not lose their MESSAGE. The text still saves,
  /// the conversation still routes, and the owner sees "sent a photo
  /// (couldn't be saved)" instead of nothing at all.
  Future<ImageKitUploadResult?> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? tags,
  }) async {
    if (!isConfigured) return null;

    final credentials = base64Encode(utf8.encode('${Env.imagekitPrivateKey}:'));

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://upload.imagekit.io/api/v1/files/upload'),
      );
      request.headers['Authorization'] = 'Basic $credentials';
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      // Always, for the same reason the browser path sets it: two
      // customers sending 'IMG_0042.jpg' must not overwrite each other.
      request.fields['useUniqueFileName'] = 'true';
      if (tags != null) request.fields['tags'] = tags;

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        Log.warning(
          'ImageKit server upload failed',
          data: {'status': streamed.statusCode, 'fileName': fileName},
        );
        return null;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      return ImageKitUploadResult(
        fileId: json['fileId'] as String,
        url: json['url'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
      );
    } catch (e) {
      Log.warning('ImageKit server upload threw', data: {'error': '$e'});
      return null;
    }
  }


  /// Fetches a public url and stores the bytes on ImageKit.
  ///
  /// Used by CSV import, where the owner supplies image links they
  /// control rather than uploading files. Taking a COPY matters: once
  /// imported, the catalog no longer depends on that source staying
  /// online, which for a link to an old store or a shared drive is not a
  /// safe assumption.
  ///
  /// The caller is responsible for rejecting private addresses BEFORE
  /// calling this — see ProductEndpoint._isPrivateHost. This method does
  /// not re-check, and that division is deliberate: the endpoint knows
  /// the request came from a customer and can refuse with a sentence,
  /// while this layer only knows about bytes.
  Future<ImageKitUploadResult?> uploadFromUrl({
    required Uri sourceUrl,
    required String fileName,
    required String folder,
  }) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(sourceUrl);
      if (response.statusCode != 200) {
        Log.warning('Media import fetch failed',
            data: {'status': response.statusCode, 'host': sourceUrl.host});
        return null;
      }
      // Same ceiling as inbound customer media. The download is buffered
      // in memory, so an unbounded fetch is a way to exhaust the server
      // with one crafted link.
      if (response.bodyBytes.length > 20 * 1024 * 1024) {
        Log.warning('Media import exceeded the size limit',
            data: {'bytes': response.bodyBytes.length});
        return null;
      }

      return uploadBytes(
        bytes: response.bodyBytes,
        fileName: fileName,
        folder: folder,
        tags: 'imported',
      );
    } catch (e) {
      Log.warning('Media import threw', data: {'error': '$e'});
      return null;
    }
  }

  /// Where inbound customer media lives.
  ///
  /// Separate from the product folder so the two never mix: product
  /// shots are the business's own asset, inbound media belongs to a
  /// conversation and is subject to whatever retention that implies.
  static String inboundFolderFor(int workspaceId) =>
      '/kola/workspaces/$workspaceId/inbound';
}

/// What an upload returned, from either path.
class ImageKitUploadResult {
  const ImageKitUploadResult({
    required this.fileId,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  final String fileId;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
}
