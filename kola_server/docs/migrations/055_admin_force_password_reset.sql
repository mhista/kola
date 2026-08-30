-- Kola — migration 055 — force a password reset on an admin account's
-- first login.
--
-- Applies AFTER 054_admin_control_plane.sql.
--
-- Defaults to true, and DELIBERATELY not backfilled to false for
-- existing rows: every admin account created so far (including the
-- first two, provisioned by hand against this table directly) was
-- given a generated placeholder password precisely because there is no
-- self-service signup — that placeholder having passed through a chat
-- transcript or a terminal is exactly the case this flag exists to
-- force a rotation out of. See admin_auth_service.dart's header for how
-- login()/verify() surface this to kola_admin, and
-- admin_auth_endpoint.dart's changePassword() for the only way it gets
-- cleared.
alter table admin_users
  add column if not exists must_reset_password boolean not null default true;
