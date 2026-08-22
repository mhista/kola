// google_calendar_service.dart — Gate 4. Plain HTTPS wrapper over Google
// Calendar API v3, same role/shape as GoogleSheetsService: everything
// that needs to talk to a business's calendar does it THROUGH this,
// never builds a googleapis.com/calendar URL directly.
//
// THE FIRST WRITE-CAPABLE PROVIDER WRAPPER IN THIS CODEBASE — every
// other provider service (Paystack, Flutterwave, Google Sheets,
// Microsoft Graph Excel, Bumpa) only ever reads. [createEvent] is a real
// write against the business's own calendar, gated by whatever calls it
// deciding whether that's safe to do right now — see
// calendar_booking.spy.yaml's header and builtin_errand_executor.dart's
// bookCalendarEvent handler for where that decision actually lives; this
// service itself has no opinion about drafts/approval, it just does the
// one write it's asked to do.
//
// TARGETS 'primary' ONLY — no calendar-picker step exists yet (unlike
// Google Sheets' setGoogleSheetTarget or OneDrive Excel's
// setExcelFileTarget, both of which let an owner choose a specific
// file). Every event is created on the connected account's own default
// calendar. A future version that lets an owner pick a secondary
// calendar just needs [calendarId] threaded through as a parameter —
// deliberately not built now since no UI collects that choice yet, and
// a hardcoded 'primary' with a documented limitation is safer than a
// parameter nothing ever sets correctly.
//
// AUTH MODEL: same as GoogleSheetsService — every call takes a fresh
// ACCESS token as an argument rather than storing one.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  const GoogleCalendarService();

  static const _baseUrl = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  /// Creates a real event on the connected account's primary calendar.
  /// [startsAt]/[endsAt] must be timezone-aware (UTC is fine — this
  /// service always sends them as UTC regardless of what the caller's
  /// DateTime carries, via .toUtc() below, so a naive local DateTime
  /// passed in by mistake still produces a correct UTC instant rather
  /// than silently treating local wall-clock digits as UTC ones).
  ///
  /// Returns the created event's Google-assigned id — callers persist
  /// this (CalendarBooking.googleEventId) so the event can be
  /// looked up/cancelled later.
  Future<String> createEvent({
    required String accessToken,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? attendeeEmail,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'summary': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'start': {
          'dateTime': startsAt.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        'end': {
          'dateTime': endsAt.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        if (attendeeEmail != null && attendeeEmail.isNotEmpty)
          'attendees': [
            {'email': attendeeEmail},
          ],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Calendar create event failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final eventId = decoded['id'] as String?;
    if (eventId == null) {
      throw Exception('Google Calendar created an event but returned no id: ${response.body}');
    }
    return eventId;
  }

  /// Cheap, side-effect-free authenticated check — confirms the access
  /// token is still valid and the calendar is still reachable, without
  /// creating anything. Used by GoogleCalendarAdapter/connector health
  /// checks, same role as GoogleSheetsService.probe.
  Future<void> probe({required String accessToken}) async {
    final uri = Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary')
        .replace(queryParameters: {'fields': 'id'});
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Calendar probe failed (${response.statusCode}): ${response.body}');
    }
  }
}
