import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/api.dart';
import '../../models/code_context.dart';
import '../../models/incident_state.dart';
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
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image == null) return;
    setState(() => status = 'Camera evidence attach ho raha hai...');
    final bytes = await File(image.path).readAsBytes();
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
      setState(() {
        codeContext = codeContext.copyWith(
          status: CodeContextStatus.received,
          result: CodeContextResult.fromJson(json, DateTime.now()),
          clearError: true,
        );
      });
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
      codeContext = CodeContextState.initial;
    }
  }

  bool _canAskForCode(Incident? active) {
    return switch (active?.status) {
      'INVESTIGATING' || 'REPRODUCING' || 'VERIFIED_FIX_READY' || 'APPROVAL_REQUIRED' || 'RECOVERED' => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CommandCenter(
        state: state,
        busy: busy,
        status: status,
        onRefresh: refresh,
        onRun: run,
        onCamera: camera,
        onVoice: voiceInput,
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
        onContinueToProposedFix: codeContext.canContinue ? continueToProposedFix : null,
      ),
      _KnowledgePage(incident: incident, codeContext: codeContext),
      _SettingsPage(state: state, status: status),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OneOps', style: TextStyle(fontWeight: FontWeight.w900)),
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
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt),
            label: 'Knowledge',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({
    required this.state,
    required this.busy,
    required this.status,
    required this.onRefresh,
    required this.onRun,
    required this.onCamera,
    required this.onVoice,
    required this.voice,
    required this.initialLoading,
  });

  final OneOpsState? state;
  final bool busy;
  final String status;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Future<Map<String, dynamic>> Function()) onRun;
  final Future<void> Function() onCamera;
  final Future<void> Function() onVoice;
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
          kicker: 'Command Center',
          title: active == null ? 'Standby, ready to catch the next incident' : 'Incident captured, control stays on phone',
          body: active == null
              ? 'Start the controlled demo incident. OneOps will show evidence, reasoning, verification and recovery gates.'
              : 'OneOps has the capsule, the safe next action, and the proof chain in one place.',
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
          title: 'Right now',
          subtitle: 'Kya toot raha hai, kya safe hai',
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
          title: 'Workflow',
          subtitle: 'Detect se recovery tak, step by step',
          child: WorkflowProgress(steps: state?.steps ?? const []),
        ),
        SectionPanel(
          title: 'Recommended action',
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
                onPressed: busy ? null : () => _runPrimary(active?.status ?? 'READY'),
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

  String _primaryAction(String status) {
    return switch (status) {
      'READY' => 'Inject demo incident',
      'DETECTED' => 'Investigate',
      'INVESTIGATING' => 'Reproduce',
      'REPRODUCING' => 'View result',
      'VERIFIED_FIX_READY' => 'Verify fix',
      'APPROVAL_REQUIRED' => 'Approve recovery',
      'RECOVERED' => 'View outcome',
      _ => 'Refresh',
    };
  }

  IconData _primaryIcon(String status) {
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
    return switch (status) {
      'READY' => 'Demo failure inject karo; live claims nahi.',
      'DETECTED' => 'Evidence hai. Ab hypothesis rank karte hain.',
      'INVESTIGATING' => 'Cause likely hai. Sandbox mein prove karo.',
      'REPRODUCING' => 'Duplicate run avoid karo; result wait karo.',
      'VERIFIED_FIX_READY' => 'Fix rehearsal passed. Formal verify karo.',
      'APPROVAL_REQUIRED' => 'Recovery tabhi jab approval complete ho.',
      'RECOVERED' => 'Service restored. Memory mein learning save.',
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
      'APPROVAL_REQUIRED' => 'Recovery is blocked until approval',
      'RECOVERED' => 'Health restored and learning recorded',
      'VERIFIED_FIX_READY' => 'Fix proof is ready for review',
      'REPRODUCING' => 'Sandbox run is active',
      'INVESTIGATING' => 'Hypothesis is being ranked',
      'DETECTED' => 'Incident Capsule is live',
      _ => 'No active incident',
    };
  }

  String _gateMessage(String status) {
    return switch (status) {
      'APPROVAL_REQUIRED' => 'Verification passed. The app still asks for explicit human recovery approval.',
      'RECOVERED' => 'Post-recovery checks passed. This incident can now become reusable memory.',
      'VERIFIED_FIX_READY' => 'The failure was reproduced and the candidate recovery passed rehearsal.',
      'REPRODUCING' => 'Duplicate execution is paused. Wait for Docker sandbox result.',
      'INVESTIGATING' => 'Observed signals are being separated from inferred cause. No auto-fix claim.',
      'DETECTED' => 'Evidence exists. Next step is correlation, not guessing.',
      _ => 'Backend is reachable when shown online. Start only the controlled lab flow.',
    };
  }

  void _runPrimary(String status) {
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
  });

  final Incident? incident;
  final CodeContextState codeContext;
  final bool canAskForCode;
  final VoidCallback onRequestCodeContext;
  final VoidCallback onCancelCodeContext;
  final VoidCallback onRetryCodeContext;
  final VoidCallback? onContinueToProposedFix;

  @override
  Widget build(BuildContext context) {
    final active = incident;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenIntro(
          kicker: 'Incident Capsule',
          title: active == null ? 'No capsule yet' : '${active.id} has evidence and reasoning',
          body: 'The capsule separates facts from inference so the developer can trust what OneOps is doing.',
        ),
        IncidentHeader(incident: active),
        const SizedBox(height: 12),
        SectionPanel(
          title: 'Incident Capsule',
          subtitle: 'Observed, inferred, retrieved, recommended',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _capsuleRow('OBSERVED', active?.summary ?? 'No incident captured.'),
              _capsuleRow('INFERRED', active?.hypothesis ?? 'No hypothesis yet.'),
              _capsuleRow('RETRIEVED', 'Similar verified incidents available after recovery.'),
              _capsuleRow('RECOMMENDED', active?.experiment ?? 'Inject or capture an incident first.'),
            ],
          ),
        ),
        SectionPanel(
          title: 'Evidence',
          subtitle: 'Compact source cards, no log dump',
          child: Column(
            children: (active?.evidence ?? const ['No evidence yet.'])
                .map((text) => EvidenceCard(text: text))
                .toList(),
          ),
        ),
        SectionPanel(
          title: 'Investigation',
          subtitle: 'AI output is guidance, not absolute truth',
          child: Column(
            children: [
              HypothesisCard(
                label: 'LEADING HYPOTHESIS',
                text: active?.hypothesis ?? 'Awaiting investigation.',
                tone: const Color(0xFF7BC7C0),
              ),
              const SizedBox(height: 8),
              ConfidenceIndicator(value: active?.confidence ?? 0),
              const SizedBox(height: 8),
              HypothesisCard(
                label: 'RECOMMENDED EXPERIMENT',
                text: active?.experiment ?? 'Run investigation first.',
                tone: const Color(0xFFFFC857),
              ),
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

class _KnowledgePage extends StatelessWidget {
  const _KnowledgePage({required this.incident, required this.codeContext});

  final Incident? incident;
  final CodeContextState codeContext;

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
          kicker: 'Proof chain',
          title: codeReady ? 'Code context attached to fix review' : 'Code context required before fix review',
          body: codeReady
              ? 'The UI makes proof visible before it allows consequential action.'
              : 'Use Ask-for-Code in Incidents to request the smallest relevant file context first.',
        ),
        SectionPanel(
          title: 'Proposed fix',
          subtitle: 'Review first, recover later',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pin dependency/config mismatch in Green API middleware',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              CodeDiffCard(ready: ready),
              const SizedBox(height: 10),
              StatusBadge(
                label: codeReady ? 'CODE CONTEXT ATTACHED' : 'WAITING FOR CODE CONTEXT',
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'Build / execution',
          subtitle: 'Progress without dumping noisy logs',
          child: BuildProgress(status: active?.status ?? 'READY'),
        ),
        SectionPanel(
          title: 'Replay & verification',
          subtitle: 'Proof before recovery',
          child: Column(
            children: [
              const ReplayTrace(title: 'ORIGINAL FAILURE TRACE', fixed: false),
              const SizedBox(height: 8),
              ReplayTrace(title: 'FIXED BUILD REPLAY', fixed: ready),
              const SizedBox(height: 10),
              StatusBadge(
                label: ready ? 'Health + functional + regression passed' : 'Verification pending',
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'Change & approval',
          subtitle: 'Enterprise gates, clearly visible',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApprovalChecklist(status: active?.status ?? 'READY'),
              const SizedBox(height: 6),
              StatusBadge(
                label: active?.status == 'RECOVERED' ? 'DEPLOYMENT COMPLETE' : 'DEPLOYMENT BLOCKED',
              ),
            ],
          ),
        ),
        SectionPanel(
          title: 'Incident memory',
          subtitle: 'Verified learnings for future RAG',
          child: IncidentMemoryCard(incident: active),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.state, required this.status});

  final OneOpsState? state;
  final String status;

  @override
  Widget build(BuildContext context) {
    final lab = state?.lab ?? const {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenIntro(
          kicker: 'Device & bridge',
          title: 'Current phone controls, workstation executes',
          body: 'Hardware-specific claims stay as placeholders until the target iQOO device is available.',
        ),
        SectionPanel(
          title: 'Connections',
          subtitle: 'Phone is control surface; workstation executes',
          child: Column(
            children: [
              MetricTile(label: 'Backend', value: status == 'Ready' ? 'Connected' : status, icon: Icons.dns),
              const SizedBox(height: 8),
              MetricTile(label: 'Blue', value: lab['blue']?.toString() ?? 'unknown', icon: Icons.circle_outlined),
              const SizedBox(height: 8),
              MetricTile(label: 'Green', value: lab['green']?.toString() ?? 'unknown', icon: Icons.circle),
              const SizedBox(height: 8),
              MetricTile(label: 'Proxy', value: lab['proxy']?.toString() ?? 'unknown', icon: Icons.hub_outlined),
            ],
          ),
        ),
        SectionPanel(
          title: 'iQOO readiness',
          subtitle: 'Placeholders only, no fake hardware claims',
          child: const Column(
            children: [
              MetricTile(label: 'Local AI', value: 'Planned adapter', icon: Icons.memory_outlined),
              SizedBox(height: 8),
              MetricTile(label: 'NPU', value: 'Awaiting target device', icon: Icons.developer_board_outlined),
              SizedBox(height: 8),
              MetricTile(label: 'Office Kit', value: 'Execution bridge status placeholder', icon: Icons.cable),
            ],
          ),
        ),
      ],
    );
  }
}
