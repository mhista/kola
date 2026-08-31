// customer_profile_endpoint.dart — Phase 13c. The read surface
// CustomerProfileRepository never had one for: `findByConversationScoped`
// existed since Phase 8b (birthday/anniversary campaigns) but was only
// ever called internally by CustomerCampaignSweepService, not exposed to
// the dashboard.
//
// Built for operations_page.dart's "Saved date" chip — the export's
// customer-context panel shows a saved birthday/anniversary alongside
// lifetime value and order history. No access gate here beyond ordinary
// workspace membership: a birthday/anniversary a bot captured is
// conversation data, not a customers.core-gated feature (unlike
// CustomerEndpoint's cross-source identity graph).

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';

class CustomerProfileEndpoint extends Endpoint {
  CustomerProfileRepository get _profiles => getIt<CustomerProfileRepository>();

  /// Null when nothing has been saved for this conversation — a
  /// perfectly normal state, not an error.
  Future<CustomerProfile?> getForConversation(
    Session session,
    String accessToken,
    int workspaceId,
    int conversationId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _profiles.findByConversationScoped(conversationId, workspaceId);
  }
}
