enum ChangeGateStatus { idle, evaluating, evaluated, failed }

class ChangeGatePolicy {
  const ChangeGatePolicy({
    this.requirePrOpen = true,
    this.requireCiPass = true,
    this.requireHumanApproval = true,
    this.requiredApprovals = 1,
    this.allowMergeFromOneOps = false,
    this.demoApproval = false,
  });

  final bool requirePrOpen;
  final bool requireCiPass;
  final bool requireHumanApproval;
  final int requiredApprovals;
  final bool allowMergeFromOneOps;
  final bool demoApproval;

  Map<String, dynamic> toJson() {
    return {
      'requirePrOpen': requirePrOpen,
      'requireCiPass': requireCiPass,
      'requireHumanApproval': requireHumanApproval,
      'requiredApprovals': requiredApprovals,
      'allowMergeFromOneOps': allowMergeFromOneOps,
      'demoApproval': demoApproval,
    };
  }

  static const standard = ChangeGatePolicy();
  static const demoApproved = ChangeGatePolicy(demoApproval: true);
}

class ChangeGateResult {
  const ChangeGateResult({
    required this.finalState,
    required this.eligible,
    required this.reasons,
    required this.checks,
    required this.pr,
  });

  final String finalState;
  final bool eligible;
  final List<String> reasons;
  final ChangeGateChecks checks;
  final ChangeGatePullRequest pr;

  factory ChangeGateResult.fromJson(Map<String, dynamic> json) {
    return ChangeGateResult(
      finalState: _text(json['finalState'], 'BLOCKED'),
      eligible: json['eligible'] == true,
      reasons: _stringList(json['reasons']),
      checks: ChangeGateChecks.fromJson(
          (json['checks'] as Map?)?.cast<String, dynamic>() ?? const {}),
      pr: ChangeGatePullRequest.fromJson(
          (json['pr'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class ChangeGateChecks {
  const ChangeGateChecks({
    required this.prOpen,
    required this.targetsMain,
    required this.ciPassed,
    required this.humanApproval,
    required this.changesRequestedClear,
    required this.policySatisfied,
  });

  final bool prOpen;
  final bool targetsMain;
  final bool ciPassed;
  final bool humanApproval;
  final bool changesRequestedClear;
  final bool policySatisfied;

  factory ChangeGateChecks.fromJson(Map<String, dynamic> json) {
    return ChangeGateChecks(
      prOpen: json['prOpen'] == true,
      targetsMain: json['targetsMain'] == true,
      ciPassed: json['ciPassed'] == true,
      humanApproval: json['humanApproval'] == true,
      changesRequestedClear: json['changesRequestedClear'] == true,
      policySatisfied: json['policySatisfied'] == true,
    );
  }
}

class ChangeGatePullRequest {
  const ChangeGatePullRequest({
    required this.prNumber,
    required this.title,
    required this.state,
    required this.merged,
    required this.baseBranch,
    required this.headBranch,
    required this.url,
    required this.latestCommitSha,
    required this.reviewStatus,
    required this.reviewDecision,
    required this.approvingReviews,
    required this.requiredApprovals,
    required this.reviewPending,
    required this.changesRequested,
    required this.ciStatus,
    required this.ciSource,
    required this.changedFiles,
    required this.reviewSource,
  });

  final int prNumber;
  final String title;
  final String state;
  final bool merged;
  final String baseBranch;
  final String headBranch;
  final String url;
  final String latestCommitSha;
  final String reviewStatus;
  final String reviewDecision;
  final int approvingReviews;
  final int requiredApprovals;
  final bool reviewPending;
  final bool changesRequested;
  final String ciStatus;
  final String ciSource;
  final List<String> changedFiles;
  final String reviewSource;

  factory ChangeGatePullRequest.fromJson(Map<String, dynamic> json) {
    return ChangeGatePullRequest(
      prNumber: _int(json['prNumber']),
      title: _text(json['title'], '-'),
      state: _text(json['state'], 'unknown'),
      merged: json['merged'] == true,
      baseBranch: _text(json['baseBranch'], '-'),
      headBranch: _text(json['headBranch'], '-'),
      url: _text(json['url'], '-'),
      latestCommitSha: _text(json['latestCommitSha'], '-'),
      reviewStatus: _text(json['reviewStatus'], 'pending'),
      reviewDecision: _text(json['reviewDecision'], 'pending'),
      approvingReviews: _int(json['approvingReviews']),
      requiredApprovals: _int(json['requiredApprovals']),
      reviewPending: json['reviewPending'] == true,
      changesRequested: json['changesRequested'] == true,
      ciStatus: _text(json['ciStatus'], 'unknown'),
      ciSource: _text(json['ciSource'], 'unknown'),
      changedFiles: _stringList(json['changedFiles']),
      reviewSource: _text(json['reviewSource'], 'GitHub PR reviews'),
    );
  }
}

class ChangeGateState {
  const ChangeGateState({
    required this.status,
    this.result,
    this.error,
  });

  final ChangeGateStatus status;
  final ChangeGateResult? result;
  final String? error;

  ChangeGateState copyWith({
    ChangeGateStatus? status,
    ChangeGateResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ChangeGateState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  static const initial = ChangeGateState(status: ChangeGateStatus.idle);
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
