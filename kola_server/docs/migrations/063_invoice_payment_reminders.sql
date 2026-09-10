-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 063 — invoice payment reminder dedupe)
--
-- Apply AFTER 062.
--
-- Phase 14L — the owner asked that Errands (and the manual "build an
-- automation" page) go away in favor of things actually auto-firing.
-- "Auto-generating payment links" was one of the owner's own named
-- examples. invoice_payment_reminder_sweep_service.dart is the real
-- implementation: a daily sweep that finds overdue invoices (status not
-- 'paid', due_at in the past — same derivation invoices_page.dart already
-- does client-side, see migration 047's header) and, where the invoice's
-- customer has a resolvable WhatsApp/Telegram conversation
-- (conversations.customer_id, see inbound_message_handler.dart's Gate 3
-- identity resolution), sends a payment reminder referencing the
-- invoice's own reference/amount/due date/payment_instructions. Invoices
-- with no resolvable channel are NOT silently skipped — they surface as
-- a WorkspaceFinding (FindingKinds.invoiceOverdue) instead, for the owner
-- to follow up manually. See that service's own header for the full
-- reasoning and workspace_sweep_service.dart's _detectInvoices detector.
--
-- These two columns are the dedupe mechanism, same shape as
-- customer_profiles.last_birthday_greeting_year /
-- last_anniversary_greeting_year (migration — see customer_profile
-- .spy.yaml's header): without them, a sweep that runs daily would remind
-- the same overdue invoice every single day forever. A reminder is sent
-- at most once every few days (see the service's own _minReminderGap) and
-- capped at a small number of total reminders per invoice, both enforced
-- in application code, not the schema — payment_reminders_sent is the
-- counter that cap reads.
-- ─────────────────────────────────────────────────────────────────────────────

alter table invoices
  add column if not exists last_payment_reminder_sent_at timestamptz,
  add column if not exists payment_reminders_sent int not null default 0;

comment on column invoices.last_payment_reminder_sent_at is
  'When InvoicePaymentReminderSweepService last actually sent a reminder for '
  'this invoice. Null means never reminded — either not yet overdue, no '
  'resolvable customer channel, or the sweep has not run since it became '
  'overdue.';

comment on column invoices.payment_reminders_sent is
  'How many reminders InvoicePaymentReminderSweepService has sent for this '
  'invoice, ever. The sweep stops reminding once this hits its own cap '
  '(see that service) — an unpaid invoice does not get messaged forever.';
