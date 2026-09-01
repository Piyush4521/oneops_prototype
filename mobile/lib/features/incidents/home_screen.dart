import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/api.dart';
import '../../models/change_gate.dart';
import '../../models/code_context.dart';
import '../../models/diagnosis.dart';
import '../../models/fix_proposal.dart';
import '../../models/incident_state.dart';
import '../../models/pr_creation.dart';
import '../../models/rag_context.dart';
import '../../widgets/oneops_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OneOpsState? state;
  var busy = false;
  var initialLoading = true;
  var status = 'Ready';
  var selectedIndex = 0;
  var voice = '';
  var codeContext = CodeContextState.initial;
  String? codeContextIncidentId;
  var codeContextRequestToken = 0;
  var ragContext = RagContextState.initial;
  var ragContextRequestToken = 0;
  var diagnosis = DiagnosisState.initial;
  var diagnosisRequestToken = 0;
  var fixProposal = FixProposalState.initial;
  var fixProposalRequestToken = 0;
  var prCreation = PrCreationState.initial;
  var prCreationRequestToken = 0;
  var changeGate = ChangeGateState.initial;
  var changeGateRequestToken = 0;
  final picker = ImagePicker();
  final speech = stt.SpeechToText();

  Incident? get incident => state?.incident;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final json = await OneOpsApi.getState();
      if (mounted) {
        setState(() {
          final nextState = OneOpsState.fromJson(json);
          _syncCodeContext(nextState);
          state = nextState;
          status = 'Ready';
          initialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          initialLoading = false;
          status = 'Backend unavailable. API jodo, phir refresh karo.';
        });
      }
    }
  }

  Future<void> run(Future<Map<String, dynamic>> Function() action) async {
    setState(() {
      busy = true;
      status = 'Working...';
    });
    try {
      await action();
      final json = await OneOpsApi.getState();
      if (mounted) {
        setState(() {
          final nextState = OneOpsState.fromJson(json);
          _syncCodeContext(nextState);
          state = nextState;
          status = 'Ready';
        });
      }
    } catch (error) {
      if (mounted) setState(() => status = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> camera() async {
    final image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image == null) return;
    setState(() => status = 'Camera evidence attach ho raha hai...');
    final bytes = await image.readAsBytes();
    try {
      await OneOpsApi.capture(
        note: 'Camera evidence captured from phone',
        imageBase64: base64Encode(bytes),
      );
      final json = await OneOpsApi.getState();
      if (mounted) {
        setState(() {
          final nextState = OneOpsState.fromJson(json);
          _syncCodeContext(nextState);
          state = nextState;
          status = 'Evidence attached to Incident Capsule.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => status = error.toString());
    }
  }

  Future<void> voiceInput() async {
    final available = await speech.initialize();
    if (!available) {
      setState(() => status = 'Voice unavailable on this device.');
      return;
    }
    setState(() => voice = 'Listening... bolo kya dekha?');
    await speech.listen(
      onResult: (result) => setState(() => voice = result.recognizedWords),
    );
  }

  Future<void> requestCodeContext() async {
    if (!_canAskForCode(incident)) {
      setState(() {
        codeContext = codeContext.copyWith(
          status: CodeContextStatus.failed,
          error: 'Run investigation before requesting code context.',
          clearResult: true,
        );
      });
      return;
    }

    final requestToken = ++codeContextRequestToken;
    setState(() {
      codeContext = codeContext.copyWith(
        status: CodeContextStatus.requesting,
        clearError: true,
        clearResult: true,
      );
    });

    try {
      final json = await OneOpsApi.requestCodeContext(
        component: codeContext.request.component,
        path: codeContext.request.fileName,
      );
      if (!mounted || requestToken != codeContextRequestToken) return;
      final result = CodeContextResult.fromJson(json, DateTime.now());
      setState(() {
        codeContext = codeContext.copyWith(
          status: CodeContextStatus.received,
          result: result,
          clearError: true,
        );
      });
      await requestRagContext(result);
    } catch (_) {
      if (!mounted || requestToken != codeContextRequestToken) return;
      setState(() {
        codeContext = codeContext.copyWith(
          status: CodeContextStatus.failed,
          error: 'Unable to retrieve code context from GitHub.',
          clearResult: true,
        );
      });
    }
  }

  Future<void> requestRagContext(CodeContextResult codeResult) async {
    final active = incident;
    if (active == null) return;
    final requestToken = ++ragContextRequestToken;
    setState(() {
      ragContext = ragContext.copyWith(
        status: RagContextStatus.requesting,
        clearError: true,
        clearResults: true,
      );
    });

    try {
      final json = await OneOpsApi.requestRagContext(
        query: _ragQuery(active),
        codeContext: codeResult.content,
      );
      if (!mounted || requestToken != ragContextRequestToken) return;
      final results = ((json['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((value) =>
              RagContextResult.fromJson(value.cast<String, dynamic>()))
          .toList();
      setState(() {
        ragContext = ragContext.copyWith(
          status: RagContextStatus.received,
          results: results,
          clearError: true,
        );
      });
      await requestDiagnosis(codeResult, results);
    } catch (_) {
      if (!mounted || requestToken != ragContextRequestToken) return;
      setState(() {
        ragContext = ragContext.copyWith(
          status: RagContextStatus.failed,
          error: 'Unable to retrieve engineering knowledge.',
          clearResults: true,
        );
      });
    }
  }

  Future<void> requestDiagnosis(
      CodeContextResult codeResult, List<RagContextResult> ragResults) async {
    final active = incident;
    if (active == null) return;
    final requestToken = ++diagnosisRequestToken;
    setState(() {
      diagnosis = diagnosis.copyWith(
        status: DiagnosisStatus.analyzing,
        clearError: true,
        clearResult: true,
      );
    });

    try {
      final json = await OneOpsApi.requestDiagnosis(
        incident: active.toJson(),
        codeContext: codeResult.toJson(),
        ragResults: ragResults.map((result) => result.toJson()).toList(),
      );
      if (!mounted || requestToken != diagnosisRequestToken) return;
      setState(() {
        diagnosis = diagnosis.copyWith(
          status: DiagnosisStatus.received,
          result: DiagnosisResult.fromJson(json),
          clearError: true,
        );
      });
      await requestFixProposal(
          codeResult, DiagnosisResult.fromJson(json), ragResults);
    } catch (_) {
      if (!mounted || requestToken != diagnosisRequestToken) return;
      setState(() {
        diagnosis = diagnosis.copyWith(
          status: DiagnosisStatus.failed,
          error: 'Unable to generate AI diagnosis.',
          clearResult: true,
        );
      });
    }
  }

  Future<void> requestFixProposal(
    CodeContextResult codeResult,
    DiagnosisResult diagnosisResult,
    List<RagContextResult> ragResults,
  ) async {
    final active = incident;
    if (active == null) return;
    final requestToken = ++fixProposalRequestToken;
    setState(() {
      fixProposal = fixProposal.copyWith(
        status: FixProposalStatus.generating,
        clearError: true,
        clearResult: true,
      );
    });

    try {
      final json = await OneOpsApi.requestFixProposal(
        diagnosis: diagnosisResult.toJson(),
        codeContext: codeResult.toJson(),
        incident: active.toJson(),
        ragResults: ragResults.map((result) => result.toJson()).toList(),
      );
      if (!mounted || requestToken != fixProposalRequestToken) return;
      setState(() {
        fixProposal = fixProposal.copyWith(
          status: FixProposalStatus.received,
          result: FixProposalResult.fromJson(json),
          clearError: true,
        );
      });
    } catch (_) {
      if (!mounted || requestToken != fixProposalRequestToken) return;
      setState(() {
        fixProposal = fixProposal.copyWith(
          status: FixProposalStatus.failed,
          error: 'Unable to generate fix proposal.',
          clearResult: true,
        );
      });
    }
  }

  Future<void> createPullRequest() async {
    final active = incident;
    final proposal = fixProposal.result;
    final codeResult = codeContext.result;
    if (active == null || proposal == null || codeResult == null) {
      setState(() {
        prCreation = prCreation.copyWith(
          status: PrCreationStatus.failed,
          error: 'Incident, proposal, and GitHub code context are required.',
          clearResult: true,
        );
      });
      return;
    }

    final requestToken = ++prCreationRequestToken;
    setState(() {
      prCreation = prCreation.copyWith(
        status: PrCreationStatus.creatingBranch,
        clearError: true,
        clearResult: true,
      );
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || requestToken != prCreationRequestToken) return;
      setState(() {
        prCreation =
            prCreation.copyWith(status: PrCreationStatus.creatingCommit);
      });
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || requestToken != prCreationRequestToken) return;
      setState(() {
        prCreation =
            prCreation.copyWith(status: PrCreationStatus.openingPullRequest);
      });

      final json = await OneOpsApi.createPullRequest(
        incident: active.toJson(),
        proposal: proposal.toJson(),
        codeContext: codeResult.toJson(),
      );
      if (!mounted || requestToken != prCreationRequestToken) return;
      setState(() {
        prCreation = prCreation.copyWith(
          status: PrCreationStatus.created,
          result: PrCreationResult.fromJson(json),
          clearError: true,
        );
        status = 'Pull request created.';
      });
      await evaluateChangeGate();
    } catch (error) {
      if (!mounted || requestToken != prCreationRequestToken) return;
      setState(() {
        prCreation = prCreation.copyWith(
          status: PrCreationStatus.failed,
          error: _safeError(error),
          clearResult: true,
        );
      });
    }
  }

  Future<void> viewPullRequest() async {
    final url = prCreation.result?.prUrl;
    if (url == null || url.trim().isEmpty || url == '-') return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pull Request'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void continueToChangeWorkflow() {
    evaluateChangeGate();
    setState(() => status = 'Evaluating change governance.');
  }

  Future<void> evaluateChangeGate(
      {ChangeGatePolicy policy = ChangeGatePolicy.standard}) async {
    final active = incident;
    final pr = prCreation.result;
    if (active == null || pr == null) {
      setState(() {
        changeGate = changeGate.copyWith(
          status: ChangeGateStatus.failed,
          error:
              'A pull request is required before change governance can be evaluated.',
          clearResult: true,
        );
      });
      return;
    }

    final requestToken = ++changeGateRequestToken;
    setState(() {
      changeGate = changeGate.copyWith(
        status: ChangeGateStatus.evaluating,
        clearError: true,
        clearResult: true,
      );
    });

    try {
      final json = await OneOpsApi.evaluateChangeGate(
        pr: pr.toJson(),
        incident: active.toJson(),
        policy: policy.toJson(),
      );
      if (!mounted || requestToken != changeGateRequestToken) return;
      setState(() {
        changeGate = changeGate.copyWith(
          status: ChangeGateStatus.evaluated,
          result: ChangeGateResult.fromJson(json),
          clearError: true,
        );
      });
    } catch (error) {
      if (!mounted || requestToken != changeGateRequestToken) return;
      setState(() {
        changeGate = changeGate.copyWith(
          status: ChangeGateStatus.failed,
          error: _safeError(error),
          clearResult: true,
        );
      });
    }
  }

  void cancelCodeContextRequest() {
    codeContextRequestToken++;
    setState(() {
      codeContext = codeContext.copyWith(
        status: CodeContextStatus.cancelled,
        clearResult: true,
        clearError: true,
      );
    });
  }

  void continueToProposedFix() {
    if (!codeContext.canContinue) return;
    setState(() => selectedIndex = 2);
  }

  void _syncCodeContext(OneOpsState nextState) {
    final nextIncidentId = nextState.incident?.id;
    if (nextIncidentId != codeContextIncidentId) {
      codeContextIncidentId = nextIncidentId;
      codeContextRequestToken++;
      ragContextRequestToken++;
      diagnosisRequestToken++;
      fixProposalRequestToken++;
      prCreationRequestToken++;
      changeGateRequestToken++;
      codeContext = CodeContextState.initial;
      ragContext = RagContextState.initial;
      diagnosis = DiagnosisState.initial;
      fixProposal = FixProposalState.initial;
      prCreation = PrCreationState.initial;
      changeGate = ChangeGateState.initial;
    }
  }

  String _ragQuery(Incident active) {
    return [
      active.summary,
      ...active.evidence,
      active.hypothesis,
      active.experiment,
    ].where((value) => value.trim().isNotEmpty).join('\n');
  }

  bool _canAskForCode(Incident? active) {
    return switch (active?.status) {
      'INVESTIGATING' ||
      'REPRODUCING' ||
      'VERIFIED_FIX_READY' ||
      'APPROVAL_REQUIRED' ||
      'RECOVERED' =>
        true,
      _ => false,
    };
  }

  String _safeError(Object error) {
    final text = error.toString();
    final match = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(text);
    if (match != null) return match.group(1)!;
    return 'Unable to create GitHub pull request.';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CommandCenter(
        state: state,
        codeContext: codeContext,
        diagnosis: diagnosis,
        fixProposal: fixProposal,
        prCreation: prCreation,
        changeGate: changeGate,
        busy: busy,
        status: status,
        onRefresh: refresh,
        onRun: run,
        onCamera: camera,
        onVoice: voiceInput,
        onOpenFix: () => setState(() => selectedIndex = 2),
        onOpenGovern: () => setState(() => selectedIndex = 3),
        voice: voice,
        initialLoading: initialLoading,
      ),
      _IncidentsPage(
        incident: incident,
        codeContext: codeContext,
        canAskForCode: _canAskForCode(incident),
        onRequestCodeContext: requestCodeContext,
        onCancelCodeContext: cancelCodeContextRequest,
        onRetryCodeContext: requestCodeContext,
        onContinueToProposedFix:
            codeContext.canContinue ? continueToProposedFix : null,
        diagnosis: diagnosis,
      ),
      _FixPage(
        incident: incident,
        codeContext: codeContext,
        ragContext: ragContext,
        diagnosis: diagnosis,
        fixProposal: fixProposal,
        prCreation: prCreation,
        onCreatePullRequest: createPullRequest,
        onViewPullRequest: viewPullRequest,
        onContinueToChangeWorkflow: continueToChangeWorkflow,
      ),
      _GovernPage(
        incident: incident,
        prCreation: prCreation,
        changeGate: changeGate,
        onEvaluateChangeGate: evaluateChangeGate,
        onEvaluateDemoApprovalGate: () =>
            evaluateChangeGate(policy: ChangeGatePolicy.demoApproved),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('OneOps', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: busy ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(onRefresh: refresh, child: pages[selectedIndex]),
          if (busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Incident',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction),
            label: 'Fix',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Govern',
          ),
        ],
      ),
    );
  }
}

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({
    required this.state,
    required this.codeContext,
    required this.diagnosis,
    required this.fixProposal,
    required this.prCreation,
    required this.changeGate,
    required this.busy,
    required this.status,
    required this.onRefresh,
    required this.onRun,
    required this.onCamera,
    required this.onVoice,
    required this.onOpenFix,
    required this.onOpenGovern,
    required this.voice,
    required this.initialLoading,
  });

  final OneOpsState? state;
  final CodeContextState codeContext;
  final DiagnosisState diagnosis;
  final FixProposalState fixProposal;
  final PrCreationState prCreation;
  final ChangeGateState changeGate;
  final bool busy;
  final String status;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Future<Map<String, dynamic>> Function()) onRun;
  final Future<void> Function() onCamera;
  final Future<void> Function() onVoice;
  final VoidCallback onOpenFix;
  final VoidCallback onOpenGovern;
  final String voice;
  final bool initialLoading;

  Incident? get incident => state?.incident;

  @override
  Widget build(BuildContext context) {
    final active = incident;
    if (initialLoading) return const LoadingSkeleton();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenIntro(
          kicker: 'OneOps',
          title: active == null ? 'Ready for demo' : _heroTitle(active.status),
          body: active == null
              ? 'Controlled incident inject karo. Evidence se solve karte hain.'
              : active.summary,
          trailing: StatusBadge(label: active?.status ?? 'READY'),
        ),
        IncidentHeader(incident: active),
        const SizedBox(height: 12),
        GateBanner(
          status: _gateStatus(active?.status ?? 'READY'),
          title: _gateTitle(active?.status ?? 'READY'),
          message: _gateMessage(active?.status ?? 'READY'),
          icon: Icons.gpp_maybe_outlined,
        ),
        const SizedBox(height: 12),
        SectionPanel(
          title: 'At a glance',
          subtitle: '3-second status',
          child: Column(
            children: [
              MetricTile(
                label: 'Connection',
                value: status == 'Ready' ? 'Backend online' : status,
                icon: Icons.router,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: MetricTile(
                      label: 'Affected',
                      value: 'Green API',
                      icon: Icons.api,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      label: 'MTTR',
                      value: active?.mttr ?? '-',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'Journey',
          subtitle: 'Detected se govern tak',
          child: WorkflowProgress(steps: state?.steps ?? const []),
        ),
        SectionPanel(
          title: 'Next best action',
          subtitle: _actionExplainer(active?.status ?? 'READY'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionButton(
                label: _primaryAction(active?.status ?? 'READY'),
                icon: _primaryIcon(active?.status ?? 'READY'),
                primary: true,
                loading: busy,
                onPressed:
                    busy ? null : () => _runPrimary(active?.status ?? 'READY'),
              ),
              ActionButton(
                label: 'Capture',
                icon: Icons.camera_alt_outlined,
                onPressed: busy ? null : onCamera,
              ),
              ActionButton(
                label: 'Voice note',
                icon: Icons.mic_none,
                onPressed: busy ? null : onVoice,
              ),
            ],
          ),
        ),
        if (voice.isNotEmpty)
          SectionPanel(
            title: 'Voice evidence',
            subtitle: 'Phone se captured note',
            child: Text(voice),
          ),
      ],
    );
  }

  String _heroTitle(String status) {
    if (fixProposal.status == FixProposalStatus.received) {
      return 'Fix ready hai';
    }
    if (diagnosis.status == DiagnosisStatus.received) {
      return 'Cause mil gaya';
    }
    if (codeContext.status == CodeContextStatus.received) {
      return 'Relevant code mil gaya';
    }
    return switch (status) {
      'DETECTED' => 'Incident aa gaya.',
      'INVESTIGATING' => 'Proof collect karte hain.',
      'REPRODUCING' => 'Sandbox check chal raha hai.',
      'VERIFIED_FIX_READY' => 'Safe to review.',
      'APPROVAL_REQUIRED' => 'Approval baaki hai.',
      'RECOVERED' => 'Sab checks green hain.',
      _ => 'Ready for demo',
    };
  }

  String _primaryAction(String status) {
    if (prCreation.status == PrCreationStatus.created ||
        changeGate.status == ChangeGateStatus.evaluated) {
      return 'Govern dekho';
    }
    if (fixProposal.status == FixProposalStatus.received &&
        prCreation.status != PrCreationStatus.created) {
      return 'Review fix';
    }
    if (codeContext.status == CodeContextStatus.received &&
        fixProposal.status != FixProposalStatus.received) {
      return 'Fix tab dekho';
    }
    return switch (status) {
      'READY' => 'Inject incident',
      'DETECTED' => 'Investigate karo',
      'INVESTIGATING' => 'Reproduce karo',
      'REPRODUCING' => 'Refresh status',
      'VERIFIED_FIX_READY' => 'Verify fix',
      'APPROVAL_REQUIRED' => 'Approve recovery',
      'RECOVERED' => 'View outcome',
      _ => 'Refresh',
    };
  }

  IconData _primaryIcon(String status) {
    if (prCreation.status == PrCreationStatus.created ||
        changeGate.status == ChangeGateStatus.evaluated) {
      return Icons.verified_user_outlined;
    }
    if (fixProposal.status == FixProposalStatus.received &&
        prCreation.status != PrCreationStatus.created) {
      return Icons.rate_review_outlined;
    }
    if (codeContext.status == CodeContextStatus.received &&
        fixProposal.status != FixProposalStatus.received) {
      return Icons.construction_outlined;
    }
    return switch (status) {
      'READY' => Icons.bug_report_outlined,
      'DETECTED' => Icons.search,
      'INVESTIGATING' => Icons.science_outlined,
      'VERIFIED_FIX_READY' => Icons.verified_outlined,
      'APPROVAL_REQUIRED' => Icons.lock_open,
      'RECOVERED' => Icons.task_alt,
      _ => Icons.refresh,
    };
  }

  String _actionExplainer(String status) {
    if (changeGate.status == ChangeGateStatus.evaluated) {
      return 'Governance result ready hai.';
    }
    if (prCreation.status == PrCreationStatus.created) {
      return 'PR ban gaya. Gate evaluate karo.';
    }
    if (fixProposal.status == FixProposalStatus.received) {
      return 'Fix ready hai. Human review ke liye PR banao.';
    }
    if (codeContext.status == CodeContextStatus.received) {
      return 'Code + RAG + diagnosis chain chal chuki hai.';
    }
    return switch (status) {
      'READY' => 'Controlled demo incident inject karo.',
      'DETECTED' => 'Evidence hai. Ab cause pakdo.',
      'INVESTIGATING' => 'Cause likely hai. Sandbox mein prove karo.',
      'REPRODUCING' => 'Duplicate run avoid karo; result wait karo.',
      'VERIFIED_FIX_READY' => 'Fix proof ready. Review path kholo.',
      'APPROVAL_REQUIRED' => 'Human yes ke bina execute nahi hoga.',
      'RECOVERED' => 'Service restored. Sab checks green hain.',
      _ => 'State sync karo.',
    };
  }

  String _gateStatus(String status) {
    return switch (status) {
      'APPROVAL_REQUIRED' => 'APPROVAL',
      'RECOVERED' => 'RECOVERED',
      'VERIFIED_FIX_READY' => 'VERIFIED',
      'REPRODUCING' => 'RUNNING',
      'INVESTIGATING' => 'SAFE',
      'DETECTED' => 'CAPTURED',
      _ => 'STANDBY',
    };
  }

  String _gateTitle(String status) {
    return switch (status) {
      'APPROVAL_REQUIRED' => 'Approval baaki hai',
      'RECOVERED' => 'Recovery complete',
      'VERIFIED_FIX_READY' => 'Fix proof ready',
      'REPRODUCING' => 'Sandbox run active',
      'INVESTIGATING' => 'Hypothesis rank ho raha hai',
      'DETECTED' => 'Incident Capsule live',
      _ => 'No active incident',
    };
  }

  String _gateMessage(String status) {
    return switch (status) {
      'APPROVAL_REQUIRED' => 'Human approval ke bina kuch execute nahi hoga.',
      'RECOVERED' => 'Post-recovery checks passed.',
      'VERIFIED_FIX_READY' =>
        'Failure reproduced, candidate fix rehearsal passed.',
      'REPRODUCING' => 'Docker sandbox result ka wait karo.',
      'INVESTIGATING' => 'Observed aur inferred alag rakhe gaye hain.',
      'DETECTED' => 'Proof hai. Guess nahi.',
      _ => 'Backend online ho to controlled lab flow start karo.',
    };
  }

  void _runPrimary(String status) {
    if (prCreation.status == PrCreationStatus.created ||
        changeGate.status == ChangeGateStatus.evaluated) {
      onOpenGovern();
      return;
    }
    if (codeContext.status == CodeContextStatus.received ||
        fixProposal.status == FixProposalStatus.received) {
      onOpenFix();
      return;
    }
    switch (status) {
      case 'READY':
        onRun(OneOpsApi.injectFailure);
        break;
      case 'DETECTED':
        onRun(OneOpsApi.investigate);
        break;
      case 'INVESTIGATING':
        onRun(OneOpsApi.reproduce);
        break;
      case 'VERIFIED_FIX_READY':
        onRun(OneOpsApi.verifyFix);
        break;
      case 'APPROVAL_REQUIRED':
        onRun(OneOpsApi.approveAndRecover);
        break;
      default:
        onRefresh();
    }
  }
}

class _IncidentsPage extends StatelessWidget {
  const _IncidentsPage({
    required this.incident,
    required this.codeContext,
    required this.canAskForCode,
    required this.onRequestCodeContext,
    required this.onCancelCodeContext,
    required this.onRetryCodeContext,
    required this.onContinueToProposedFix,
    required this.diagnosis,
  });

  final Incident? incident;
  final CodeContextState codeContext;
  final bool canAskForCode;
  final VoidCallback onRequestCodeContext;
  final VoidCallback onCancelCodeContext;
  final VoidCallback onRetryCodeContext;
  final VoidCallback? onContinueToProposedFix;
  final DiagnosisState diagnosis;

  @override
  Widget build(BuildContext context) {
    final active = incident;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenIntro(
          kicker: 'Incident Capsule',
          title: active == null ? 'No capsule yet' : 'Incident aa gaya.',
          body: active?.summary ?? 'Proof collect karte hain. Guess nahi.',
        ),
        IncidentHeader(incident: active),
        const SizedBox(height: 12),
        SectionPanel(
          title: 'Journey',
          subtitle: 'Detected, evidence, code, diagnosis, fix, review',
          child: WorkflowProgress(steps: active?.steps ?? const []),
        ),
        SectionPanel(
          title: 'Incident Capsule',
          subtitle: 'Observed, inferred, retrieved, recommended',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _capsuleRow(
                  'OBSERVED', active?.summary ?? 'No incident captured.'),
              _capsuleRow(
                  'INFERRED', active?.hypothesis ?? 'No hypothesis yet.'),
              _capsuleRow('RETRIEVED',
                  'Similar verified incidents available after recovery.'),
              _capsuleRow('RECOMMENDED',
                  active?.experiment ?? 'Inject or capture an incident first.'),
            ],
          ),
        ),
        SectionPanel(
          title: 'Evidence',
          subtitle: 'Proof hai. Guess nahi.',
          child: Column(
            children: (active?.evidence ?? const ['No evidence yet.'])
                .map((text) => EvidenceCard(text: text))
                .toList(),
          ),
        ),
        SectionPanel(
          title: 'Investigation',
          subtitle: 'Guidance hai, absolute truth nahi',
          child: Column(
            children: [
              HypothesisCard(
                label: 'LEADING HYPOTHESIS',
                text: active?.hypothesis ?? 'Awaiting investigation.',
                tone: const Color(0xFF2F80ED),
              ),
              const SizedBox(height: 8),
              ConfidenceIndicator(value: active?.confidence ?? 0),
              const SizedBox(height: 8),
              HypothesisCard(
                label: 'RECOMMENDED EXPERIMENT',
                text: active?.experiment ?? 'Pehle investigate karo.',
                tone: const Color(0xFFFFC857),
              ),
              const SizedBox(height: 8),
              DiagnosisPanel(state: diagnosis),
            ],
          ),
        ),
        AskForCodePanel(
          state: codeContext,
          available: canAskForCode,
          onRequest: onRequestCodeContext,
          onCancel: onCancelCodeContext,
          onRetry: onRetryCodeContext,
          onContinue: onContinueToProposedFix,
        ),
      ],
    );
  }

  Widget _capsuleRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: label),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _FixPage extends StatelessWidget {
  const _FixPage({
    required this.incident,
    required this.codeContext,
    required this.ragContext,
    required this.diagnosis,
    required this.fixProposal,
    required this.prCreation,
    required this.onCreatePullRequest,
    required this.onViewPullRequest,
    required this.onContinueToChangeWorkflow,
  });

  final Incident? incident;
  final CodeContextState codeContext;
  final RagContextState ragContext;
  final DiagnosisState diagnosis;
  final FixProposalState fixProposal;
  final PrCreationState prCreation;
  final VoidCallback onCreatePullRequest;
  final VoidCallback onViewPullRequest;
  final VoidCallback onContinueToChangeWorkflow;

  @override
  Widget build(BuildContext context) {
    final active = incident;
    final backendReady = active?.status == 'VERIFIED_FIX_READY' ||
        active?.status == 'APPROVAL_REQUIRED' ||
        active?.status == 'RECOVERED';
    final codeReady = codeContext.canContinue;
    final ready = backendReady && codeReady;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenIntro(
          kicker: 'Fix',
          title: codeReady ? 'Fix ready hone wala hai' : 'Code context chahiye',
          body: codeReady
              ? 'Observed evidence, GitHub source, RAG aur diagnosis ek saath.'
              : 'Incident tab se affected file request karo.',
        ),
        SectionPanel(
          title: 'Inputs',
          subtitle: 'Observed, retrieved, inferred',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _knowledgeRow(
                  'OBSERVED', active?.summary ?? 'No incident captured.'),
              const SizedBox(height: 8),
              _knowledgeRow(
                'CODE CONTEXT',
                codeContext.result?.path ??
                    'Waiting for GitHub source context.',
              ),
              const SizedBox(height: 8),
              _knowledgeRow(
                'RETRIEVED KNOWLEDGE',
                ragContext.status == RagContextStatus.received
                    ? '${ragContext.results.length} supporting sources returned.'
                    : 'Waiting for local retrieval.',
              ),
            ],
          ),
        ),
        RagContextPanel(state: ragContext),
        SectionPanel(
          title: 'Fix ready hai',
          subtitle: 'Review first. Deploy shortcut nahi.',
          child: FixProposalPanel(
            state: fixProposal,
            diagnosis: diagnosis.result,
            fallbackReady: ready,
            prCreation: prCreation,
            onCreatePullRequest: onCreatePullRequest,
            onViewPullRequest: onViewPullRequest,
            onContinueToChangeWorkflow: onContinueToChangeWorkflow,
          ),
        ),
      ],
    );
  }

  Widget _knowledgeRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: label),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _GovernPage extends StatelessWidget {
  const _GovernPage({
    required this.incident,
    required this.prCreation,
    required this.changeGate,
    required this.onEvaluateChangeGate,
    required this.onEvaluateDemoApprovalGate,
  });

  final Incident? incident;
  final PrCreationState prCreation;
  final ChangeGateState changeGate;
  final VoidCallback onEvaluateChangeGate;
  final VoidCallback onEvaluateDemoApprovalGate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenIntro(
          kicker: 'Govern',
          title: _title,
          body: 'Fix ready hai. Human approval ke bina kuch execute nahi hoga.',
          trailing:
              StatusBadge(label: changeGate.result?.finalState ?? 'LOCKED'),
        ),
        SectionPanel(
          title: 'Change governance',
          subtitle: 'GitHub facts alag, OneOps policy alag',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChangeGatePanel(
                state: changeGate,
                onEvaluate: onEvaluateChangeGate,
                onDemoApproval: onEvaluateDemoApprovalGate,
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'PR card',
          subtitle: 'Actual GitHub result jab available ho',
          child: Column(
            children: [
              MetricTile(
                label: 'Pull request',
                value: prCreation.result == null
                    ? 'PR pending'
                    : '#${prCreation.result!.prNumber}',
                icon: Icons.rate_review_outlined,
              ),
              const SizedBox(height: 8),
              MetricTile(
                label: 'Branch',
                value: prCreation.result?.branch ?? 'Waiting',
                icon: Icons.account_tree_outlined,
              ),
              const SizedBox(height: 8),
              MetricTile(
                label: 'Target',
                value: prCreation.result?.base ?? 'main',
                icon: Icons.merge_type_outlined,
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'Execution lock',
          subtitle: 'No bypass, no push to main',
          child: GateBanner(
            status: incident?.status == 'RECOVERED' ? 'RECOVERED' : 'LOCKED',
            title: incident?.status == 'RECOVERED'
                ? 'Recovery complete'
                : 'Approval baaki hai',
            message: 'Human yes ke bina execute nahi hoga.',
            icon: Icons.lock_outline,
          ),
        ),
      ],
    );
  }

  String get _title {
    if (changeGate.result?.eligible == true) {
      return 'Safe to proceed';
    }
    if (prCreation.status == PrCreationStatus.created) {
      return 'Approval baaki hai';
    }
    return 'Execution locked';
  }
}
