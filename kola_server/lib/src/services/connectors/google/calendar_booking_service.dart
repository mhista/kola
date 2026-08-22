// calendar_booking_service.dart — Gate 4. The draft-vs-immediate branch
// point for the Google Calendar connector, same role
// PaymentCheckoutService plays for collectPayment: the built-in Errand
// handler (builtin_errand_executor.dart) stays a thin wrapper, this is
// where the actual decision and both code paths live.
//
// See calendar_booking.spy.yaml's header for the full reasoning. Short
// version: [bookingMode] is a per-workspace setting
// (ConnectorEndpoint.setCalendarBookingMode), read out of the SAME
// encrypted config blob that already holds the OAuth refresh token — not
// a new column, since it isn't itself secret, it just configures the
// connection it lives alongside. UNSET (a connection made before this
// setting existed) defaults to 'draft', the safer option, never
// 'immediate' by omission.

import 'dart:convert';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/calendar_booking_repository.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'google_oauth_service.dart';
import 'google_calendar_service.dart';

/// Thrown when a workspace has no working Google Calendar connection —
/// lets the errand handler give the customer an honest, non-alarming
/// reply instead of a raw exception, same pattern as
/// InvalidPaymentGatewayCredentialException/InvalidWhatsAppChannelException.
class CalendarNotConnectedException implements Exception {
  final String message;
  const CalendarNotConnectedException(this.message);

  @override
  String toString() => 'CalendarNotConnectedException: $message';
}

class CalendarBookingService {
  CalendarBookingService({
    required WorkspaceConnectorRepository connectors,
    required CalendarBookingRepository bookings,
    required GoogleOAuthService oauth,
    GoogleCalendarService? calendar,
  })  : _connectors = connectors,
        _bookings = bookings,
        _oauth = oauth,
        _calendar = calendar ?? const GoogleCalendarService();

  final WorkspaceConnectorRepository _connectors;
  final CalendarBookingRepository _bookings;
  final GoogleOAuthService _oauth;
  final GoogleCalendarService _calendar;

  /// Requests a booking. In draft mode this writes a 'pending' row and
  /// returns immediately — nothing is written to Google. In immediate
  /// mode this calls Google Calendar right away and returns a 'booked'
  /// row. Either way, the returned [CalendarBooking] is what the caller
  /// (bookCalendarEvent) builds its customer-facing reply from.
  Future<CalendarBooking> requestBooking({
    required int workspaceId,
    int? conversationId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
  }) async {
    final connector = await _connectors.findByWorkspaceAndKey(workspaceId, 'google_calendar');
    if (connector == null || connector.status != 'connected' || connector.encryptedConfig == null) {
      throw const CalendarNotConnectedException(
        'This business has not connected Google Calendar yet.',
      );
    }

    final config = jsonDecode(
      ChannelCredentialEncryptionService.decrypt(connector.encryptedConfig!),
    ) as Map<String, dynamic>;
    final refreshToken = config['refreshToken'] as String?;
    if (refreshToken == null) {
      throw const CalendarNotConnectedException(
        'This business\'s Google Calendar connection is missing its sign-in.',
      );
    }
    // Default 'draft' — see this file's header. Never 'immediate' unless
    // an owner explicitly chose it via setCalendarBookingMode.
    final bookingMode = (config['bookingMode'] as String?) ?? 'draft';

    if (bookingMode != 'immediate') {
      return _bookings.create(
        workspaceId: workspaceId,
        conversationId: conversationId,
        title: title,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        attendeeName: attendeeName,
        attendeeEmail: attendeeEmail,
        attendeePhone: attendeePhone,
        status: 'pending',
      );
    }

    final tokens = await _oauth.refreshAccessToken(refreshToken);
    final accessToken = tokens['access_token'] as String?;
    if (accessToken == null) {
      throw const CalendarNotConnectedException(
        'Google did not return a valid access token for this business\'s calendar.',
      );
    }

    final eventId = await _calendar.createEvent(
      accessToken: accessToken,
      title: title,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      attendeeEmail: attendeeEmail,
    );

    return _bookings.create(
      workspaceId: workspaceId,
      conversationId: conversationId,
      title: title,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      attendeeName: attendeeName,
      attendeeEmail: attendeeEmail,
      attendeePhone: attendeePhone,
      status: 'booked',
      googleEventId: eventId,
    );
  }
}
