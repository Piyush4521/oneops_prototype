enum RagContextStatus { idle, requesting, received, failed }

class RagContextResult {
  const RagContextResult({
    required this.source,
    required this.title,
    required this.excerpt,
    required this.score,
  });

  final String source;
  final String title;
  final String excerpt;
  final double score;

  factory RagContextResult.fromJson(Map<String, dynamic> json) {
    return RagContextResult(
      source: _text(json['source'], '-'),
      title: _text(json['title'], 'Retrieved source'),
      excerpt: _text(json['excerpt'], ''),
      score: _double(json['score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'title': title,
      'excerpt': excerpt,
      'score': score,
    };
  }
}

class RagContextState {
  const RagContextState({
    required this.status,
    required this.results,
    this.error,
  });

  final RagContextStatus status;
  final List<RagContextResult> results;
  final String? error;

  RagContextState copyWith({
    RagContextStatus? status,
    List<RagContextResult>? results,
    String? error,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return RagContextState(
      status: status ?? this.status,
      results: clearResults ? const [] : results ?? this.results,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial = RagContextState(
    status: RagContextStatus.idle,
    results: [],
  );
}

String _text(Object? value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
