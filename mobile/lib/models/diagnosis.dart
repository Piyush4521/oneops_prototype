enum DiagnosisStatus { idle, analyzing, received, failed }

class DiagnosisResult {
  const DiagnosisResult({
    required this.rootCause,
    required this.confidence,
    required this.evidence,
    required this.alternativeCause,
    required this.risk,
    required this.recommendation,
    required this.affectedFiles,
  });

  final String rootCause;
  final int confidence;
  final List<String> evidence;
  final String alternativeCause;
  final String risk;
  final String recommendation;
  final List<String> affectedFiles;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      rootCause: _text(json['rootCause'], 'No root cause returned.'),
      confidence: _int(json['confidence']),
      evidence: ((json['evidence'] as List?) ?? const [])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      alternativeCause: _text(json['alternativeCause'], 'No alternative returned.'),
      risk: _text(json['risk'], 'No risk returned.'),
      recommendation: _text(json['recommendation'], 'No recommendation returned.'),
      affectedFiles: ((json['affectedFiles'] as List?) ?? const [])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rootCause': rootCause,
      'confidence': confidence,
      'evidence': evidence,
      'alternativeCause': alternativeCause,
      'risk': risk,
      'recommendation': recommendation,
      'affectedFiles': affectedFiles,
    };
  }
}

class DiagnosisState {
  const DiagnosisState({
    required this.status,
    this.result,
    this.error,
  });

  final DiagnosisStatus status;
  final DiagnosisResult? result;
  final String? error;

  DiagnosisState copyWith({
    DiagnosisStatus? status,
    DiagnosisResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return DiagnosisState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial = DiagnosisState(status: DiagnosisStatus.idle);
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
