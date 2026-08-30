class OneOpsState {
  const OneOpsState({
    required this.incident,
    required this.steps,
    required this.lab,
  });

  final Incident? incident;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> lab;

  factory OneOpsState.fromJson(Map<String, dynamic> json) {
    final incidentJson = json['incident'];
    final incident = incidentJson is Map<String, dynamic>
        ? Incident.fromJson(incidentJson)
        : null;
    return OneOpsState(
      incident: incident,
      steps: incident?.steps ?? const [],
      lab: (json['lab'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class Incident {
  const Incident({
    required this.id,
    required this.status,
    required this.severity,
    required this.confidence,
    required this.summary,
    required this.createdAt,
    required this.mttr,
    required this.evidence,
    required this.hypothesis,
    required this.experiment,
    required this.steps,
    required this.history,
  });

  final String id;
  final String status;
  final String severity;
  final int confidence;
  final String summary;
  final String createdAt;
  final String mttr;
  final List<String> evidence;
  final String hypothesis;
  final String experiment;
  final List<WorkflowStep> steps;
  final List<HistoryEvent> history;

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: _text(json['id'], 'NO INCIDENT'),
      status: _text(json['status'], 'READY'),
      severity: _text(json['severity'], '-'),
      confidence: _int(json['confidence']),
      summary: _text(json['summary'], 'No active incident.'),
      createdAt: _text(json['createdAt'], '-'),
      mttr: _text(json['mttr'], '-'),
      evidence: ((json['evidence'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
      hypothesis: _text(json['hypothesis'], 'No hypothesis yet.'),
      experiment: _text(json['experiment'], 'No experiment selected.'),
      steps: ((json['steps'] as List?) ?? const [])
          .whereType<Map>()
          .map((value) => WorkflowStep.fromJson(value.cast<String, dynamic>()))
          .toList(),
      history: ((json['history'] as List?) ?? const [])
          .whereType<Map>()
          .map((value) => HistoryEvent.fromJson(value.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class WorkflowStep {
  const WorkflowStep({
    required this.id,
    required this.label,
    required this.done,
    required this.detail,
  });

  final String id;
  final String label;
  final bool done;
  final String detail;

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: _text(json['id'], ''),
      label: _text(json['label'], 'Workflow step'),
      done: json['done'] == true,
      detail: _text(json['detail'], ''),
    );
  }
}

class HistoryEvent {
  const HistoryEvent({required this.at, required this.event});

  final String at;
  final String event;

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      at: _text(json['at'], '-'),
      event: _text(json['event'], 'Workflow event'),
    );
  }
}

String _text(Object? value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
