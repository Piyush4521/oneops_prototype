enum PrCreationStatus {
  readyToReview,
  creatingBranch,
  creatingCommit,
  openingPullRequest,
  created,
  failed,
}

class PrCreationResult {
  const PrCreationResult({
    required this.repository,
    required this.branch,
    required this.commit,
    required this.prNumber,
    required this.prUrl,
    required this.base,
  });

  final String repository;
  final String branch;
  final String commit;
  final int prNumber;
  final String prUrl;
  final String base;

  factory PrCreationResult.fromJson(Map<String, dynamic> json) {
    return PrCreationResult(
      repository: _text(json['repository'], '-'),
      branch: _text(json['branch'], '-'),
      commit: _text(json['commit'], '-'),
      prNumber: _int(json['prNumber']),
      prUrl: _text(json['prUrl'], '-'),
      base: _text(json['base'], 'main'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repository': repository,
      'branch': branch,
      'commit': commit,
      'prNumber': prNumber,
      'prUrl': prUrl,
      'base': base,
    };
  }
}

class PrCreationState {
  const PrCreationState({
    required this.status,
    this.result,
    this.error,
  });

  final PrCreationStatus status;
  final PrCreationResult? result;
  final String? error;

  bool get isCreating {
    return status == PrCreationStatus.creatingBranch ||
        status == PrCreationStatus.creatingCommit ||
        status == PrCreationStatus.openingPullRequest;
  }

  PrCreationState copyWith({
    PrCreationStatus? status,
    PrCreationResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return PrCreationState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial =
      PrCreationState(status: PrCreationStatus.readyToReview);
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
