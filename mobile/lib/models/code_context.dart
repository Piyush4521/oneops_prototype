enum CodeContextStatus { idle, requesting, received, failed, cancelled }

class CodeContextRequest {
  const CodeContextRequest({
    required this.component,
    required this.fileName,
    required this.reason,
    required this.evidence,
    required this.scope,
  });

  final String component;
  final String fileName;
  final String reason;
  final List<String> evidence;
  final List<String> scope;

  static const requestMiddleware = CodeContextRequest(
    component: 'RequestMiddleware',
    fileName: 'request_middleware.dart',
    reason: 'Runtime exception follows the Green deployment dependency change.',
    evidence: [
      'Runtime error: TypeError in request middleware',
      'Deployment correlation: Green promoted before error spike',
      'Dependency change: request path configuration changed',
    ],
    scope: [
      'request parsing',
      'dependency configuration',
      'middleware error handling',
    ],
  );
}

class CodeContextResult {
  const CodeContextResult({
    required this.fileName,
    required this.sourceSummary,
    required this.sourceOrigin,
    required this.receivedAt,
    required this.repository,
    required this.path,
    required this.ref,
    required this.commit,
    required this.source,
    required this.content,
  });

  final String fileName;
  final String sourceSummary;
  final String sourceOrigin;
  final DateTime receivedAt;
  final String repository;
  final String path;
  final String ref;
  final String commit;
  final String source;
  final String content;

  factory CodeContextResult.fromJson(Map<String, dynamic> json, DateTime receivedAt) {
    return CodeContextResult(
      fileName: _text(json['path'], CodeContextRequest.requestMiddleware.fileName).split('/').last,
      sourceSummary: 'Read-only source context retrieved for the requested component.',
      sourceOrigin: _text(json['source'], 'GitHub'),
      receivedAt: receivedAt,
      repository: _text(json['repository'], '-'),
      path: _text(json['path'], '-'),
      ref: _text(json['ref'], '-'),
      commit: _text(json['commit'], '-'),
      source: _text(json['source'], 'GitHub'),
      content: _text(json['content'], ''),
    );
  }
}

class CodeContextState {
  const CodeContextState({
    required this.status,
    required this.request,
    this.result,
    this.error,
  });

  final CodeContextStatus status;
  final CodeContextRequest request;
  final CodeContextResult? result;
  final String? error;

  bool get canContinue => status == CodeContextStatus.received;

  CodeContextState copyWith({
    CodeContextStatus? status,
    CodeContextResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CodeContextState(
      status: status ?? this.status,
      request: request,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial = CodeContextState(
    status: CodeContextStatus.idle,
    request: CodeContextRequest.requestMiddleware,
  );
}

String _text(Object? value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
