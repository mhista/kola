// log_entry.dart — one line in Structured Mode's Logs tab, matching
// Kola Bot Detail Dev.dc.html's logs. Mock data here; real data is
// kola_server's ErrandExecutionLog (Phase 3b/3c) once kola_client
// wiring exists.

class LogEntry {
  const LogEntry({required this.time, required this.text});

  final String time;
  final String text;
}
