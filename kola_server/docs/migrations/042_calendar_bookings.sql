-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 042 — calendar bookings)
--
-- Apply AFTER 041.
--
-- The Google Calendar connector is the first WRITE-capable connector in
-- this codebase — every prior adapter (Paystack, Flutterwave, Google
-- Sheets, OneDrive Excel, Bumpa) is a read-only mirror pulling data IN.
-- Booking an appointment or a delivery means kola creates a real event
-- on the business's own calendar, which is exactly the kind of action
-- that needs the human-in-the-loop guardrail the product vision's
-- Automation Engine layer always described but nothing in this codebase
-- has needed to build yet — every existing built-in Errand
-- (collectPayment, createSupportTicket, recordCustomerProfile...)
-- executes immediately the instant it's invoked, none of them pause for
-- approval first.
--
-- calendar_bookings is that pause point. A workspace's connection
-- setting (bookingMode: 'draft' | 'immediate', stored in
-- workspace_connectors.encrypted_config alongside the OAuth refresh
-- token — not a new column here, since it isn't itself secret but lives
-- with the connection it configures) decides which path a request takes:
--   draft mode      -> a row lands here as 'pending', nothing is written
--                       to Google yet, an owner approves or rejects it.
--   immediate mode  -> GoogleCalendarService.createEvent is called right
--                       away, and the row here is written already
--                       'booked', mainly for audit/history rather than
--                       as a real gate.
--
-- Same "proposal queue an owner confirms" shape migration 039's
-- customer_merge_proposals already established for a different kind of
-- decision — reused here rather than inventing a second one.

create table if not exists calendar_bookings (
    id               bigserial   primary key,
    workspace_id     bigint      not null references workspaces (id) on delete cascade,

    -- Which conversation this request came from, if any — a booking can
    -- in principle be created outside a conversation later (a
    -- dashboard-initiated booking), so this is nullable rather than
    -- forcing every booking to pretend one exists.
    conversation_id  bigint      references conversations (id) on delete set null,

    title            text        not null,
    description      text,

    starts_at        timestamptz not null,
    ends_at          timestamptz not null,
    check (ends_at > starts_at),

    -- Who the appointment/delivery is for — captured as plain text
    -- fields rather than a customer_id foreign key, because the AI that
    -- proposes a booking mid-conversation knows a name/phone/email from
    -- what the customer just said, not a resolved Customer row (the
    -- same reason payment_transactions stores customer_email/phone
    -- directly rather than requiring a resolved id up front).
    attendee_name    text,
    attendee_email   text,
    attendee_phone   text,

    -- 'pending' | 'approved' | 'rejected' | 'booked'. 'approved' is a
    -- transient state an owner's confirm click passes through on its
    -- way to 'booked' once the real Google event is actually created —
    -- kept distinct from 'booked' so a booking that was approved but
    -- whose Google Calendar write then failed (token revoked, etc.) is
    -- visibly stuck rather than silently indistinguishable from success.
    status           text        not null default 'pending'
                     check (status in ('pending', 'approved', 'rejected', 'booked')),

    -- Set once the real Google Calendar event exists — Google's own
    -- event id, needed if this booking is ever cancelled/updated later.
    google_event_id  text,

    resolved_by_email text,
    resolved_at       timestamptz,

    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

create index if not exists calendar_bookings_workspace_status_idx
    on calendar_bookings (workspace_id, status, created_at desc);

create or replace trigger calendar_bookings_updated_at
    before update on calendar_bookings for each row execute function update_updated_at();

-- RLS enabled, no policies — deny-all to PostgREST, matching every table
-- in this project since migration 001.
alter table calendar_bookings enable row level security;
-- ─────────────────────────────────────────────────────────────────────────────
