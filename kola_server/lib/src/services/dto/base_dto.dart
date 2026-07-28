// base_dto.dart
//
// Every DTO in the system implements this interface.
//
// WHY DTOs EXIST (plain English):
//   Serverpod generates clean Dart model classes from .spy.yaml files.
//   Supabase stores data as JSON rows in Postgres, with snake_case columns.
//   These two worlds don't speak the same language directly.
//
//   A DTO (Data Transfer Object) is the translator between them. It knows
//   how to:
//     • Turn a Supabase JSON row  → a Serverpod model  (fromRow)
//     • Turn a Serverpod model    → a Supabase row map (toRow)
//
//   This is the same "Serverpod Mini" pattern already proven in
//   degenbot_server — Serverpod owns model shape + codegen + the generated
//   client; Supabase owns the actual schema and persistence; the DTO+
//   Repository layer bridges the two. Confirmed as the right call for Kola
//   in SRS.md §2 (avoids the DB-coupling problems full-Serverpod-ORM caused
//   in asami_server).
//
//   Practical payoff: if we ever switch persistence providers, only the
//   DTOs and repositories change — every endpoint and business-logic file
//   keeps working untouched, because they only ever see Serverpod model
//   types, never raw Supabase JSON maps.

/// Contract that every DTO must satisfy.
///
/// [T] is the Serverpod model type (e.g. Workspace, Bot, Channel).
abstract class BaseDto<T> {
  const BaseDto();

  /// Convert a Supabase row (Map<String, dynamic>) into a Serverpod model.
  T fromRow(Map<String, dynamic> row);

  /// Convert a Serverpod model into a Supabase row map ready for insert/upsert.
  /// Pass [includeId: false] on inserts (let Supabase assign the id).
  Map<String, dynamic> toRow(T model, {bool includeId = false});
}
