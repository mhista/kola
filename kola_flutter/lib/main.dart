// kola_flutter — placeholder scaffold. NOT a shipping app yet.
//
// ── WHY THIS FILE WAS EMPTIED ────────────────────────────────────────
//
// Until Aug 2026 this was the unmodified Serverpod starter template. It
// called `client.greeting.hello(...)` — an endpoint that has never
// existed in kola_server. The template ships with one; this project
// deleted it when the real endpoints were written and never touched the
// Flutter side.
//
// So this was not a regression. It was the ONLY compile error in the
// entire workspace, and it had been there since the project began,
// quietly failing in a package nobody was building. Worth recording as
// its own small lesson: a package that is never compiled is a package
// that is never correct, and a workspace-wide `dart analyze` is what
// surfaces it.
//
// ── WHAT THIS PACKAGE IS FOR ─────────────────────────────────────────
//
// Reserved, per BUILD_AUDIT_5 §2.6, as the possible native wrapper for
// the sales counter specifically. A PWA cannot reach a USB or serial
// receipt printer — WebUSB/WebSerial is Chrome-desktop only and absent
// from iOS Safari entirely — so if kola ever needs to drive a thermal
// printer, cash drawer or barcode scanner directly, it happens here.
//
// That decision is NOT made yet. Option 1 (network/Bluetooth ESC-POS
// printers, which work from the PWA) may make this package unnecessary.
// Nothing should be built here until the peripheral strategy is settled,
// because it changes what the checkout screen can offer.
//
// Deliberately NOT deleted: the package is a real workspace member with
// a working kola_client path dependency, and re-creating that scaffold
// later costs more than keeping a file that compiles to a placeholder.
//
// Deliberately NOT given a demo endpoint call: every real endpoint
// requires an accessToken and a workspaceId, and inventing an
// unauthenticated one purely so this screen has something to display
// would be adding server surface to justify a placeholder.

import 'package:flutter/material.dart';

void main() {
  runApp(const KolaFlutterApp());
}

class KolaFlutterApp extends StatelessWidget {
  const KolaFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kola',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34A37E)),
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('kola')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Reserved for the native sales-counter wrapper.\n'
            'Nothing is built here yet — see this file’s header.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
