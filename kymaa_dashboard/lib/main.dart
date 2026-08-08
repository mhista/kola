// main.dart — entry point. Kept to exactly this per the working
// convention (see kola_landing/lib/main.dart) that pages/components
// live in their own files; all real content lives in app.dart and
// lib/components/.

import 'package:jaspr/jaspr.dart';
import 'app.dart';

void main() {
  runApp(const DashboardApp());
}
