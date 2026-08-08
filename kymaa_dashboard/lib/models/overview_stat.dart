// overview_stat.dart — one tile in Structured Mode's Overview tab stats
// grid, matching Kola Bot Detail Dev.dc.html's overviewStats. Mock data
// here; real data is an aggregate over ErrandExecutionLog + Conversation
// rows once kola_client wiring exists.

class OverviewStat {
  const OverviewStat({required this.label, required this.value});

  final String label;
  final String value;
}
