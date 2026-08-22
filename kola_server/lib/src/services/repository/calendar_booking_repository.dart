// calendar_booking_repository.dart — Gate 4. Storage for the Google
// Calendar connector's approval queue. See calendar_booking.spy.yaml's
// header for why this exists at all — the first write-capable connector
// in this codebase needs a pause point that no prior connector did.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/calendar_booking_dto.dart';
import 'supabase_client.dart';

final _log = Logger('CalendarBookingRepository');
const _dto = CalendarBookingDto();

class CalendarBookingRepository {
  const CalendarBookingRepository();

  Future<CalendarBooking> create({
    required int workspaceId,
    int? conversationId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    required String status, // 'pending' (draft mode) or 'booked' (immediate mode)
    String? googleEventId,
  }) async {
    final now = DateTime.now().toUtc();
    final inserted = await supabase
        .from('calendar_bookings')
        .insert({
          'workspace_id': workspaceId,
          'conversation_id': conversationId,
          'title': title,
          'description': description,
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt.toUtc().toIso8601String(),
          'attendee_name': attendeeName,
          'attendee_email': attendeeEmail,
          'attendee_phone': attendeePhone,
          'status': status,
          'google_event_id': googleEventId,
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();
    return _dto.fromRow(inserted);
  }

  Future<CalendarBooking?> findById(int workspaceId, int bookingId) async {
    final row = await supabase
        .from('calendar_bookings')
        .select()
        .eq('id', bookingId)
        .eq('workspace_id', workspaceId)
        .maybeSingle();
    return row == null ? null : _dto.fromRow(row);
  }

  Future<List<CalendarBooking>> listPending(int workspaceId) async {
    _log.fine('listPending($workspaceId)');
    final response = await supabase
        .from('calendar_bookings')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'pending')
        .order('starts_at', ascending: true);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Marks a pending booking 'approved' — the transient state on its way
  /// to 'booked' once GoogleCalendarService.createEvent actually
  /// succeeds. See migration 042's header on why this is a distinct step
  /// from [markBooked] rather than jumping straight there.
  Future<CalendarBooking> markApproved(int bookingId, {required String resolvedByEmail}) async {
    final row = await supabase
        .from('calendar_bookings')
        .update({
          'status': 'approved',
          'resolved_by_email': resolvedByEmail,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', bookingId)
        .select()
        .single();
    return _dto.fromRow(row);
  }

  Future<CalendarBooking> markRejected(int bookingId, {required String resolvedByEmail}) async {
    final row = await supabase
        .from('calendar_bookings')
        .update({
          'status': 'rejected',
          'resolved_by_email': resolvedByEmail,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', bookingId)
        .select()
        .single();
    return _dto.fromRow(row);
  }

  Future<CalendarBooking> markBooked(int bookingId, {required String googleEventId}) async {
    final row = await supabase
        .from('calendar_bookings')
        .update({
          'status': 'booked',
          'google_event_id': googleEventId,
        })
        .eq('id', bookingId)
        .select()
        .single();
    return _dto.fromRow(row);
  }
}
