const defaultPolicy = {
  requirePrOpen: true,
  requireCiPass: true,
  requireHumanApproval: true,
  requiredApprovals: 1,
  allowMergeFromOneOps: false,
  demoApproval: false,
};

export function defaultChangeGatePolicy() {
  return { ...defaultPolicy };
}

export function evaluateChangeGate({ pr, incident, policy } = {}) {
  const effectivePolicy = normalizePolicy(policy);
  const demoApproval = effectivePolicy.demoApproval === true;
  const realApprovalCount = Number(pr?.approvingReviews || 0);
  const approvalSatisfied = realApprovalCount >= effectivePolicy.requiredApprovals;
  const humanApproval = effectivePolicy.requireHumanApproval
    ? approvalSatisfied || demoApproval
    : true;
  const prOpen = effectivePolicy.requirePrOpen ? pr?.state === 'open' && pr?.merged !== true : true;
  const targetsMain = pr?.baseBranch === 'main';
  const ciPassed = effectivePolicy.requireCiPass ? pr?.ciStatus === 'passed' : true;
  const noChangesRequested = pr?.changesRequested !== true;
  const policySatisfied = prOpen && targetsMain && ciPassed && humanApproval && noChangesRequested;
  const finalState = policySatisfied
    ? 'READY_FOR_EXECUTION'
    : prOpen && targetsMain && ciPassed && noChangesRequested
      ? 'READY_FOR_APPROVAL'
      : 'BLOCKED';

  return {
    status: 'evaluated',
    finalState,
    eligible: finalState === 'READY_FOR_EXECUTION',
    reasons: buildReasons({ pr, effectivePolicy, realApprovalCount, demoApproval, prOpen, targetsMain, ciPassed, humanApproval, noChangesRequested }),
    checks: {
      prOpen,
      targetsMain,
      ciPassed,
      humanApproval,
      changesRequestedClear: noChangesRequested,
      policySatisfied,
    },
    policy: effectivePolicy,
    pr: {
      prNumber: pr?.prNumber || 0,
      title: pr?.title || '',
      state: pr?.state || 'unknown',
      merged: pr?.merged === true,
      baseBranch: pr?.baseBranch || '',
      headBranch: pr?.headBranch || '',
      url: pr?.url || '',
      latestCommitSha: pr?.latestCommitSha || '',
      reviewStatus: demoApproval && !approvalSatisfied ? 'demo_approved' : pr?.reviewStatus || 'pending',
      reviewDecision: pr?.reviewDecision || pr?.reviewStatus || 'pending',
      approvingReviews: realApprovalCount,
      requiredApprovals: effectivePolicy.requiredApprovals,
      reviewPending: pr?.reviewPending === true,
      changesRequested: pr?.changesRequested === true,
      ciStatus: pr?.ciStatus || 'unknown',
      ciSource: pr?.ciSource || 'unknown',
      ciDetails: Array.isArray(pr?.ciDetails) ? pr.ciDetails : [],
      changedFiles: Array.isArray(pr?.changedFiles) ? pr.changedFiles : [],
      reviewSource: demoApproval && !approvalSatisfied ? 'OneOps Demo Approval' : 'GitHub PR reviews',
    },
    incidentId: incident?.id || '',
  };
}

function normalizePolicy(policy = {}) {
  return {
    requirePrOpen: policy.requirePrOpen ?? defaultPolicy.requirePrOpen,
    requireCiPass: policy.requireCiPass ?? defaultPolicy.requireCiPass,
    requireHumanApproval: policy.requireHumanApproval ?? defaultPolicy.requireHumanApproval,
    requiredApprovals: Math.max(0, Number(policy.requiredApprovals ?? defaultPolicy.requiredApprovals)),
    allowMergeFromOneOps: policy.allowMergeFromOneOps === true,
    demoApproval: policy.demoApproval === true,
  };
}

function buildReasons({ pr, effectivePolicy, realApprovalCount, demoApproval, prOpen, targetsMain, ciPassed, humanApproval, noChangesRequested }) {
  const reasons = [];
  reasons.push(prOpen ? 'PR is open and unmerged' : 'PR must be open and unmerged');
  reasons.push(targetsMain ? 'PR targets main' : 'PR must target main');
  reasons.push(ciPassed ? 'CI checks passed' : `CI status is ${pr?.ciStatus || 'unknown'}`);
  if (effectivePolicy.requireHumanApproval) {
    if (humanApproval && demoApproval && realApprovalCount < effectivePolicy.requiredApprovals) {
      reasons.push('OneOps Demo Approval satisfies prototype policy only; this is not a GitHub approval');
    } else {
      reasons.push(humanApproval
        ? `${realApprovalCount} GitHub approval(s) satisfy policy`
        : `${effectivePolicy.requiredApprovals} human approval required`);
    }
  } else {
    reasons.push('Human approval is not required by policy');
  }
  reasons.push(noChangesRequested ? 'No GitHub review changes requested' : 'GitHub review changes are requested');
  if (effectivePolicy.allowMergeFromOneOps === false) {
    reasons.push('OneOps merge is disabled by policy');
  }
  return reasons;
}
