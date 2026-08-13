-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 027 — owner name on workspace creation)
--
-- Apply AFTER 026.
--
-- ── WHY ──────────────────────────────────────────────────────────────────────
--
-- Kola Create Workspace.dc.html is a three-step wizard whose state is
-- { step, bizName, archetype, ownerName, ownerPhone }. The server took two of
-- those four:
--
--   bizName    → workspaces.name           ✅
--   archetype  → workspaces.industry_tag   ✅
--   ownerName  → NOWHERE
--   ownerPhone → NOWHERE
--
-- So the wizard asked a first-time owner for their name and phone number and
-- silently discarded both. Asking for something and dropping it is worse than
-- not asking: it costs the owner trust the first time they notice.
--
-- ── ownerName LIVES ON THE WORKSPACE, NOT THE MEMBER ─────────────────────────
--
-- Arguably it belongs on workspace_members — it describes a PERSON, and the
-- same person could later join a second workspace under a different name.
-- It goes here anyway, and the reason is what the field is FOR.
--
-- This is the name kola greets them with and signs messages as. It is a
-- property of "who runs this business", captured at the moment the business
-- is created, by the one member who definitionally exists then — the owner.
-- Putting it on the member row would mean a workspace with no members (a
-- state that cannot occur, but which the schema permits) has no owner name,
-- and every read would need a join to answer "what do I call this person".
--
-- If team members ever get their own display names, those belong on
-- workspace_members and this stays as the business's owner-of-record. Two
-- different questions, deliberately two different columns.
--
-- ── ownerPhone GETS NO COLUMN AT ALL ─────────────────────────────────────────
--
-- Deliberate. There is already a correct home for it:
-- owner_notification_settings.owner_whatsapp_number.
--
-- Adding workspaces.owner_phone would create a SECOND copy of the same fact,
-- and the two would drift the first time an owner changed their number in
-- notification settings — leaving kola messaging a stale number while the
-- profile showed a current one. The endpoint writes the wizard's number
-- straight into notification settings instead.
--
-- The payoff is real: escalation alerts work from the moment the workspace
-- exists, rather than after a settings visit the owner does not know to make.
-- ─────────────────────────────────────────────────────────────────────────────

alter table workspaces
    add column if not exists owner_name text;

comment on column workspaces.owner_name is
    'The name kola greets the owner with and signs messages as. Captured in '
    'the create-workspace wizard. NOT a login identity — that is Supabase '
    'auth — and not a per-member display name.';
