enum FixProposalStatus { idle, generating, received, failed }

class FixProposalResult {
  const FixProposalResult({
    required this.title,
    required this.summary,
    required this.affectedFiles,
    required this.diff,
    required this.reasoning,
    required this.confidence,
    required this.risk,
    required this.expectedOutcome,
    required this.validationPlan,
  });

  final String title;
  final String summary;
  final List<String> affectedFiles;
  final String diff;
  final String reasoning;
  final int confidence;
  final String risk;
  final String expectedOutcome;
  final List<String> validationPlan;

  factory FixProposalResult.fromJson(Map<String, dynamic> json) {
    return FixProposalResult(
      title: _text(json['title'], 'PROPOSED CHANGE - FOR REVIEW'),
      summary: _text(json['summary'], 'Proposal awaiting review.'),
      affectedFiles: _stringList(json['affectedFiles']),
      diff: _text(json['diff'], ''),
      reasoning: _text(json['reasoning'], 'No reasoning returned.'),
      confidence: _int(json['confidence']),
      risk: _text(json['risk'], 'MEDIUM'),
      expectedOutcome: _text(json['expectedOutcome'], 'No expected outcome returned.'),
      validationPlan: _stringList(json['validationPlan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'affectedFiles': affectedFiles,
      'diff': diff,
      'reasoning': reasoning,
      'confidence': confidence,
      'risk': risk,
      'expectedOutcome': expectedOutcome,
      'validationPlan': validationPlan,
    };
  }
}

class FixProposalState {
  const FixProposalState({
    required this.status,
    this.result,
    this.error,
  });

  final FixProposalStatus status;
  final FixProposalResult? result;
  final String? error;

  FixProposalState copyWith({
    FixProposalStatus? status,
    FixProposalResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return FixProposalState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial = FixProposalState(status: FixProposalStatus.idle);
}

List<String> _stringList(Object? value) {
  return ((value as List?) ?? const [])
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList();
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
