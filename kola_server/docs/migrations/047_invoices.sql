-- 047_invoices.sql
--
-- Invoice — the A4 invoice tab on Documents (docs/TILL_DOCUMENTS_STATUS.md
-- suggested-next-steps item 4: "A4 invoicing... needs its own design pass
-- (an Invoice/Order entity)"). Read this header before touching
-- invoice_endpoint.dart or invoice.spy.yaml.
--
-- WHY lines_json, NOT AN invoice_lines CHILD TABLE (unlike sale/sale_lines) —
-- this is a deliberate deviation from that established pattern, not an
-- oversight. This session found and fixed a real Serverpod bug: neither a
-- custom-model List<T> NOR a plain List<int?> can be deserialized as a
-- direct endpoint PARAMETER on this install (see sale_endpoint.dart's
-- ringUpSale header for the full trace — it landed in the FRAMEWORK's own
-- internal protocol.dart, never this app's). ringUpSale's fix was sending
-- lines as one JSON-encoded String. Rather than build a second three-column-
-- array workaround (ProductEndpoint.replaceVariants' shape) or a whole
-- second child table + repository + DTO for what is, here, read-mostly and
-- never queried by an individual line, invoices store their lines the same
-- proven way: one JSON array column, decoded server-side. If invoice lines
-- ever need their own queries (e.g. "which invoices contain product X"),
-- that is the trigger to split this into a real child table — not before.
--
-- STATUS LIFECYCLE (owner-driven, not automatic): draft -> sent -> viewed ->
-- partly_paid -> paid. 'overdue' is NEVER stored — it is derived at read
-- time from (status not in ('paid') and due_at < now()), computed in
-- kola_dashboard, not here. Storing it would need a daily sweep to keep
-- correct as today's date moves past due_at with nothing else changing;
-- deriving it is always correct and costs nothing.
--
-- paid_minor is running-total bookkeeping ONLY, same posture as
-- payment_transaction.spy.yaml's holdStatus: this migration does not wire
-- automatic webhook -> invoice reconciliation (that is Gate 13 in the
-- roadmap doc, fully unbuilt) — the "Pay now" button starts a REAL checkout
-- through PaymentEndpoint.initializeCheckout against the workspace's own
-- connected gateway, but confirming that payment and crediting paid_minor
-- is a manual "mark as paid" today, not an automatic webhook credit. Stated
-- plainly rather than silently half-built.

create table if not exists invoices (
  id bigint generated always as identity primary key,
  workspace_id bigint not null references workspaces(id) on delete cascade,

  -- Optional links. A standalone invoice (no prior till sale) has both
  -- null — invoicing does not require having rung something up first.
  customer_id bigint references customers(id) on delete set null,
  sale_id bigint references sales(id) on delete set null,

  reference text not null,
  -- 'draft' | 'sent' | 'viewed' | 'partly_paid' | 'paid'
  status text not null default 'draft',

  bill_to_name text not null,
  bill_to_address text,
  bill_to_phone text,

  -- JSON array of {"name": string, "quantity": int, "unitPriceMinor": int}.
  -- See this file's header for why this is JSON, not a child table.
  lines_json text not null,

  subtotal_minor bigint not null,
  tax_rate_bps int not null default 0,
  tax_minor bigint not null default 0,
  total_minor bigint not null,
  paid_minor bigint not null default 0,
  currency text not null default 'NGN',

  payment_instructions text,

  issued_at timestamptz not null default now(),
  due_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists invoices_workspace_reference_idx
  on invoices (workspace_id, reference);
create index if not exists invoices_workspace_idx on invoices (workspace_id);
create index if not exists invoices_customer_idx on invoices (customer_id);
create index if not exists invoices_sale_idx on invoices (sale_id);
