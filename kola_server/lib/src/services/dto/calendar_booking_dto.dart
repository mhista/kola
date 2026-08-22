// calendar_booking_dto.dart — Gate 4.
//
// Supabase table: calendar_bookings
// Schema: docs/migrations/042_calendar_bookings.sql

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class CalendarBookingDto extends BaseDto<CalendarBooking> {
  const CalendarBookingDto();

  @override
  CalendarBooking fromRow(Map<String, dynamic> row) {
    return CalendarBooking(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      conversationId: row['conversation_id'] as int?,
      title: row['title'] as String,
      description: row['description'] as String?,
      startsAt: DateTime.parse(row['starts_at'] as String),
      endsAt: DateTime.parse(row['ends_at'] as String),
      attendeeName: row['attendee_name'] as String?,
      attendeeEmail: row['attendee_email'] as String?,
      attendeePhone: row['attendee_phone'] as String?,
      status: row['status'] as String,
      googleEventId: row['google_event_id'] as String?,
      resolvedByEmail: row['resolved_by_email'] as String?,
      resolvedAt: row['resolved_at'] == null
          ? null
          : DateTime.parse(row['resolved_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(CalendarBooking model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'conversation_id': model.conversationId,
      'title': model.title,
      'description': model.description,
      'starts_at': model.startsAt.toIso8601String(),
      'ends_at': model.endsAt.toIso8601String(),
      'attendee_name': model.attendeeName,
      'attendee_email': model.attendeeEmail,
      'attendee_phone': model.attendeePhone,
      'status': model.status,
      'google_event_id': model.googleEventId,
      'resolved_by_email': model.resolvedByEmail,
      'resolved_at': model.resolvedAt?.toIso8601String(),
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
