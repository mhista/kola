// tool/test_builtin_errand.dart
//
// One-off script exercising Phase 3b's "built-in Errand type working
// first" bar: registers (or reuses) an 'escalateToHuman' Errand and
// actually runs it through BuiltinErrandExecutor, confirming the
// execution gets logged either way. Same spirit as the other tool/
// scripts — bypasses Session/requireWorkspaceAccess since nothing calls
// ErrandEndpoint from a real UI yet.
//
// USAGE (run from kola_server/):
//   dart run tool/test_builtin_errand.dart --reason="customer asked about a refund I can't approve"
//
// First run creates a throwaway workspace + Errand (prints their ids).
// Pass --workspace-id=<id> --errand-id=<id> on later runs to reuse the
// same Errand instead of creating a new one each time.

import 'dart:io';
import 'package:kola_server/src/services/repository/supabase_client.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_execution_log_repository.dart';
import 'package:kola_server/src/services/errand/builtin_errand_executor.dart';
import 'package:kola_server/src/services/billing/payment_checkout_service.dart';
import 'package:kola_server/src/services/repository/support_ticket_repository.dart';
import 'package:kola_server/src/services/repository/customer_profile_repository.dart';
import 'package:kola_server/src/services/repository/otp_code_repository.dart';
import 'package:kola_server/src/services/otp/otp_service.dart';
import 'package:kola_server/src/services/messaging/whatsapp/whatsapp_template_creation_service.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final reason = flags['reason'] ?? 'testing the built-in Errand executor';

  await initSupabase();

  final workspaces = const WorkspaceRepository();
  final errands = const ErrandRepository();
  final executionLogs = const ErrandExecutionLogRepository();
  // Task #128/#130/#132/#140/#154 — collectPayment, createSupportTicket,
  // recordCustomerProfile, sendOtp, verifyOtp, and createProductListTemplate
  // each need their own dependency too now, even though this script only
  // ever exercises escalateToHuman; the constructor requires them
  // regardless of which handler a given run actually calls.
  final executor = BuiltinErrandExecutor(
    executionLogs: executionLogs,
    paymentCheckout: PaymentCheckoutService(),
    supportTickets: const SupportTicketRepository(),
    customerProfiles: const CustomerProfileRepository(),
    otpService: OtpService(otpCodes: const OtpCodeRepository()),
    whatsAppTemplates: WhatsAppTemplateCreationService(),
  );

  var workspace = flags.containsKey('workspace-id')
      ? await workspaces.findById(int.parse(flags['workspace-id']!))
      : null;
  workspace ??= await workspaces.create(name: 'Kola Test Workspace (Errand)');
  print('Workspace: id=${workspace.id} name=${workspace.name}');

  var errand = flags.containsKey('errand-id')
      ? await errands.findByIdScoped(int.parse(flags['errand-id']!), workspace.id!)
      : null;
  errand ??= await errands.create(
    workspaceId: workspace.id!,
    name: 'Hand off to a person',
    descriptionForAi:
        'Use this when the customer needs something a human should handle '
        '— a refund decision, a complaint, or anything outside what this '
        'bot can confidently answer on its own.',
    source: 'builtin',
    builtinHandlerKey: 'escalateToHuman',
    createdVia: 'api',
  );
  print('Errand: id=${errand.id} name=${errand.name} builtinHandlerKey=${errand.builtinHandlerKey}');

  print('');
  print('Executing with reason: "$reason"');
  print('');

  try {
    final result = await executor.execute(errand: errand, input: {'reason': reason});
    print('✅ Execution succeeded and was logged:');
    print('   ${result}');
    print('');
    print('Check errand_execution_logs (workspace_id=${workspace.id}, '
        'errand_id=${errand.id}) in Supabase to see the logged row.');
    exit(0);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    stderr.writeln('(This failure was still logged — check errand_execution_logs.)');
    exit(1);
  }
}

Map<String, String> _parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--') || !arg.contains('=')) continue;
    final eqIndex = arg.indexOf('=');
    map[arg.substring(2, eqIndex)] = arg.substring(eqIndex + 1);
  }
  return map;
}
