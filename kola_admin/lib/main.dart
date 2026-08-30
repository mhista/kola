// main.dart — entry point. Kept minimal per the same convention every
// other Jaspr app in this project follows (kola_landing/kola_dashboard):
// all real content lives in app.dart and lib/pages/.

import 'package:jaspr/jaspr.dart';

import 'app.dart';

void main() {
  runApp(const AdminApp());
}
