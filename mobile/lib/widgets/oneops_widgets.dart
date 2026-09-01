import 'package:flutter/material.dart';

import '../models/change_gate.dart';
import '../models/code_context.dart';
import '../models/diagnosis.dart';
import '../models/fix_proposal.dart';
import '../models/incident_state.dart';
import '../models/pr_creation.dart';
import '../models/rag_context.dart';

const _surface = Color(0xFFFFFCF5);
const _surfaceSoft = Color(0xFFFFF2C2);
const _border = Color(0xFF162033);
const _accent = Color(0xFFF5B700);
const _success = Color(0xFF18864B);
const _warning = Color(0xFFFFC857);
const _danger = Color(0xFFE85D4F);
const _muted = Color(0xFF697386);
const _ink = Color(0xFF162033);
const _blue = Color(0xFF2F80ED);

Color statusColor(String status) {
  if (status.contains('RECOVERED') || status.contains('VERIFIED')) {
    return _success;
  }
  if (status.contains('FAIL') || status.contains('BLOCKED')) return _danger;
  if (status.contains('APPROVAL') || status.contains('REPRODUCING')) {
    return _warning;
  }
  if (status.contains('CI') || status.contains('GIT')) return _blue;
  return _ink;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == _ink ? 0.06 : 0.14),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == _warning ? _ink : color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class SectionPanel extends StatelessWidget {
  const SectionPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border, width: 1.4),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F162033),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ScreenIntro extends StatelessWidget {
  const ScreenIntro({
    super.key,
    required this.kicker,
    required this.title,
    required this.body,
    this.trailing,
  });

  final String kicker;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _warning,
        border: Border.all(color: _border, width: 1.6),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33162033),
            offset: Offset(4, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: _ink,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentHeader extends StatelessWidget {
  const IncidentHeader({super.key, required this.incident});

  final Incident? incident;

  @override
  Widget build(BuildContext context) {
    final active = incident;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border, width: 1.4),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24162033),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  active?.id ?? 'ONEOPS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: active?.severity ?? 'STANDBY'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            active?.summary ?? 'No active incident. System shant hai.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(label: active?.status ?? 'READY'),
              StatusBadge(
                label: 'Confidence ${active?.confidence ?? 0}%',
                tone: _blue,
              ),
              StatusBadge(label: active?.mttr ?? 'MTTR -', tone: _success),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? _accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: _ink, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GateBanner extends StatelessWidget {
  const GateBanner({
    super.key,
    required this.status,
    required this.title,
    required this.message,
    this.icon = Icons.security,
  });

  final String status;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == _warning ? 0.38 : 0.11),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(color: _ink, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
              child: Align(
            alignment: Alignment.topRight,
            child: StatusBadge(label: status),
          )),
        ],
      ),
    );
  }
}

class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Confidence',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('$clamped%',
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: clamped / 100,
            backgroundColor: _surfaceSoft,
            valueColor:
                AlwaysStoppedAnimation(statusColor('$clamped VERIFIED')),
          ),
        ),
      ],
    );
  }
}

class WorkflowProgress extends StatelessWidget {
  const WorkflowProgress({super.key, required this.steps});

  final List<WorkflowStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Text(
        'Incident inject karo to workflow stages yahan appear honge.',
        style: TextStyle(color: _muted),
      );
    }
    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                step.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: step.done ? _success : _muted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (step.detail.isNotEmpty)
                      Text(step.detail,
                          style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class EvidenceCard extends StatelessWidget {
  const EvidenceCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final source = text.contains(':') ? text.split(':').first : 'Evidence';
    final body =
        text.contains(':') ? text.substring(text.indexOf(':') + 1) : text;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: _accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.toUpperCase(),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body.trim(), style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HypothesisCard extends StatelessWidget {
  const HypothesisCard({
    super.key,
    required this.label,
    required this.text,
    required this.tone,
  });

  final String label;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: tone, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class CodeDiffCard extends StatelessWidget {
  const CodeDiffCard({super.key, required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final lines = [
      ('+', 'pin middleware dependency version'),
      ('+', 'add regression check for request middleware'),
      ('-', 'no direct deploy from phone'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1117),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.difference_outlined, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Candidate change',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              StatusBadge(label: ready ? 'REVIEWABLE' : 'LOCKED'),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map((line) {
            final added = line.$1 == '+';
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      line.$1,
                      style: TextStyle(
                        color: added ? _success : _danger,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.$2,
                      style: const TextStyle(
                          fontFamily: 'monospace', height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class BuildProgress extends StatelessWidget {
  const BuildProgress({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final reproducing = status == 'REPRODUCING';
    final verified = status == 'VERIFIED_FIX_READY' ||
        status == 'APPROVAL_REQUIRED' ||
        status == 'RECOVERED';
    final rows = [
      ('Office Kit bridge', 'Placeholder ready', false),
      ('Workstation', 'Connected through backend', true),
      (
        'Docker sandbox',
        reproducing
            ? 'Testing'
            : verified
                ? 'Completed'
                : 'Waiting',
        reproducing || verified
      ),
      (
        'Verification',
        verified ? 'Completed' : 'Blocked until reproduction',
        verified
      ),
    ];
    return Column(
      children: [
        ...rows.map((row) {
          final active = row.$3;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              border: Border.all(
                  color: active ? _accent.withValues(alpha: 0.45) : _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(active ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: active ? _success : _muted),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(row.$1,
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(row.$2,
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          );
        }),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.terminal, color: _accent),
              title: const Text('View technical logs',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Short operational summary only',
                  style: TextStyle(color: _muted, fontSize: 12)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1117),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'REPRODUCING'
                        ? 'sandbox: running targeted reproduction\npolicy: recovery disabled until verification'
                        : 'sandbox: waiting for command\npolicy: no production recovery without approval',
                    style: const TextStyle(
                        fontFamily: 'monospace', color: _muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AskForCodePanel extends StatelessWidget {
  const AskForCodePanel({
    super.key,
    required this.state,
    required this.available,
    required this.onRequest,
    required this.onCancel,
    required this.onRetry,
    required this.onContinue,
  });

  final CodeContextState state;
  final bool available;
  final VoidCallback onRequest;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final request = state.request;
    return SectionPanel(
      title: 'Code context',
      subtitle: 'Sirf affected file. Full repo expose nahi hoga.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GateBanner(
            status: _statusLabel,
            title: _title,
            message: _message,
            icon: Icons.code,
          ),
          const SizedBox(height: 12),
          MetricTile(
            label: 'Affected component',
            value: request.component,
            icon: Icons.integration_instructions_outlined,
          ),
          const SizedBox(height: 8),
          MetricTile(
            label: 'Requested file',
            value: request.fileName,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          _Subsection(
            title: 'Why',
            child: Text(request.reason, style: const TextStyle(height: 1.35)),
          ),
          _Subsection(
            title: 'Evidence',
            child: Column(
              children: request.evidence
                  .map(
                    (item) => _CheckRow(
                      label: item,
                      icon: Icons.check_circle,
                      color: _success,
                    ),
                  )
                  .toList(),
            ),
          ),
          _Subsection(
            title: 'Requested context',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: request.scope
                  .map((item) => StatusBadge(label: item, tone: _accent))
                  .toList(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, color: _accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Relevant code chahiye? OneOps read-only context mangwata hai.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (state.status == CodeContextStatus.received &&
              state.result != null) ...[
            _ReceivedContext(result: state.result!),
            const SizedBox(height: 12),
          ],
          if (state.status == CodeContextStatus.failed &&
              state.error != null) ...[
            _ErrorCallout(message: state.error!),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (state.status == CodeContextStatus.requesting)
                ActionButton(
                  label: 'Cancel request',
                  icon: Icons.close,
                  onPressed: onCancel,
                )
              else
                ActionButton(
                  label: state.status == CodeContextStatus.failed
                      ? 'Retry karo'
                      : 'Code mangwao',
                  icon: Icons.code,
                  primary: true,
                  loading: state.status == CodeContextStatus.requesting,
                  onPressed: available
                      ? (state.status == CodeContextStatus.failed
                          ? onRetry
                          : onRequest)
                      : null,
                ),
              ActionButton(
                label: 'Fix dekho',
                icon: Icons.arrow_forward,
                onPressed: onContinue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _statusLabel {
    return switch (state.status) {
      CodeContextStatus.idle => available ? 'READY' : 'LOCKED',
      CodeContextStatus.requesting => 'REQUESTING',
      CodeContextStatus.received => 'RECEIVED',
      CodeContextStatus.failed => 'FAILED',
      CodeContextStatus.cancelled => 'CANCELLED',
    };
  }

  String get _title {
    return switch (state.status) {
      CodeContextStatus.idle =>
        available ? 'Relevant code chahiye?' : 'Pehle investigation karo',
      CodeContextStatus.requesting => 'Code aa raha hai...',
      CodeContextStatus.received => 'Code mil gaya',
      CodeContextStatus.failed => 'Code request fail hua',
      CodeContextStatus.cancelled => 'Code request cancelled',
    };
  }

  String get _message {
    return switch (state.status) {
      CodeContextStatus.idle => available
          ? 'Sirf affected file mangwa rahe hain. Full repo expose nahi hoga.'
          : 'Cause narrow karo, phir GitHub context request hoga.',
      CodeContextStatus.requesting =>
        'GitHub se read-only source context fetch ho raha hai.',
      CodeContextStatus.received =>
        'Retrieved context diagnosis aur fix proposal mein use hoga.',
      CodeContextStatus.failed =>
        'Backend error real hai. Connection theek karke retry karo.',
      CodeContextStatus.cancelled =>
        'Cancel ke baad repository data attach nahi hua.',
    };
  }
}

class _ReceivedContext extends StatelessWidget {
  const _ReceivedContext({required this.result});

  final CodeContextResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.09),
        border: Border.all(color: _success.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: _success, size: 20),
              SizedBox(width: 8),
              Text('CODE MIL GAYA',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          MetricTile(
              label: 'Repository',
              value: result.repository,
              icon: Icons.storage_outlined),
          const SizedBox(height: 8),
          MetricTile(
              label: 'Path',
              value: result.path,
              icon: Icons.description_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: MetricTile(
                      label: 'Branch',
                      value: result.ref,
                      icon: Icons.account_tree_outlined)),
              const SizedBox(width: 8),
              Expanded(
                  child: MetricTile(
                      label: 'Commit',
                      value: _shortCommit(result.commit),
                      icon: Icons.commit)),
            ],
          ),
          const SizedBox(height: 8),
          MetricTile(
              label: 'Source',
              value: result.source,
              icon: Icons.source_outlined),
          const SizedBox(height: 8),
          MetricTile(
            label: 'Received',
            value: _formatTime(result.receivedAt),
            icon: Icons.schedule,
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined, color: _accent),
                title: const Text('Source preview',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(result.fileName,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1117),
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _preview(result.content),
                      style: const TextStyle(
                          fontFamily: 'monospace', color: _ink, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _shortCommit(String commit) {
    if (commit.length <= 12) return commit;
    return commit.substring(0, 12);
  }

  String _preview(String content) {
    if (content.length <= 1200) return content;
    return '${content.substring(0, 1200)}\n\n... preview truncated in mobile UI';
  }
}

class RagContextPanel extends StatelessWidget {
  const RagContextPanel({super.key, required this.state});

  final RagContextState state;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Similar cases mile',
      subtitle: 'Local RAG sources, compact view',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: _statusLabel),
          const SizedBox(height: 12),
          if (state.status == RagContextStatus.requesting)
            const LinearProgressIndicator(minHeight: 2),
          if (state.status == RagContextStatus.idle)
            const Text(
              'Code milte hi OneOps local engineering knowledge search karega.',
              style: TextStyle(color: _muted, height: 1.35),
            ),
          if (state.status == RagContextStatus.failed)
            _ErrorCallout(
                message:
                    state.error ?? 'Unable to retrieve engineering knowledge.'),
          if (state.status == RagContextStatus.received &&
              state.results.isEmpty)
            const Text(
              'Current evidence aur code context se koi source match nahi hua.',
              style: TextStyle(color: _muted, height: 1.35),
            ),
          if (state.results.isNotEmpty)
            ...state.results.map((result) => _RagResultCard(result: result)),
        ],
      ),
    );
  }

  String get _statusLabel {
    return switch (state.status) {
      RagContextStatus.idle => 'RETRIEVAL WAITING',
      RagContextStatus.requesting => 'RAG SEARCHING',
      RagContextStatus.received => 'KNOWLEDGE READY',
      RagContextStatus.failed => 'RETRIEVAL FAILED',
    };
  }
}

class DiagnosisPanel extends StatelessWidget {
  const DiagnosisPanel({super.key, required this.state});

  final DiagnosisState state;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Cause mil gaya',
      subtitle: 'Guidance hai, absolute truth nahi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: _statusLabel),
          const SizedBox(height: 12),
          if (state.status == DiagnosisStatus.analyzing)
            const LinearProgressIndicator(minHeight: 2),
          if (state.status == DiagnosisStatus.idle)
            const Text(
              'Code context aur RAG ke baad diagnosis yahan dikhega.',
              style: TextStyle(color: _muted, height: 1.35),
            ),
          if (state.status == DiagnosisStatus.failed)
            _ErrorCallout(
                message: state.error ?? 'Unable to generate AI diagnosis.'),
          if (state.status == DiagnosisStatus.received && state.result != null)
            _DiagnosisResultView(result: state.result!),
        ],
      ),
    );
  }

  String get _statusLabel {
    return switch (state.status) {
      DiagnosisStatus.idle => 'DIAGNOSIS WAITING',
      DiagnosisStatus.analyzing => 'AI SOCH RAHA HAI',
      DiagnosisStatus.received => 'CAUSE FOUND',
      DiagnosisStatus.failed => 'DIAGNOSIS FAILED',
    };
  }
}

class FixProposalPanel extends StatelessWidget {
  const FixProposalPanel({
    super.key,
    required this.state,
    required this.diagnosis,
    required this.fallbackReady,
    required this.prCreation,
    required this.onCreatePullRequest,
    required this.onViewPullRequest,
    required this.onContinueToChangeWorkflow,
  });

  final FixProposalState state;
  final DiagnosisResult? diagnosis;
  final bool fallbackReady;
  final PrCreationState prCreation;
  final VoidCallback onCreatePullRequest;
  final VoidCallback onViewPullRequest;
  final VoidCallback onContinueToChangeWorkflow;

  @override
  Widget build(BuildContext context) {
    if (state.status == FixProposalStatus.received && state.result != null) {
      return _FixProposalResultView(
        result: state.result!,
        diagnosis: diagnosis,
        prCreation: prCreation,
        onCreatePullRequest: onCreatePullRequest,
        onViewPullRequest: onViewPullRequest,
        onContinueToChangeWorkflow: onContinueToChangeWorkflow,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GateBanner(
          status: _statusLabel,
          title: state.status == FixProposalStatus.generating
              ? 'Fix draft ho raha hai'
              : 'Fix abhi locked hai',
          message: fallbackReady
              ? 'Backend state ready hai, proposal data ka wait hai.'
              : 'Diagnosis complete hote hi reviewable fix yahan aayega.',
          icon: Icons.construction_outlined,
        ),
        const SizedBox(height: 10),
        StatusBadge(label: _statusLabel),
        const SizedBox(height: 10),
        if (state.status == FixProposalStatus.generating)
          const LinearProgressIndicator(minHeight: 2),
        if (state.status == FixProposalStatus.idle)
          const Text(
            'AI diagnosis ke bina OneOps fix draft nahi karega.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
        if (state.status == FixProposalStatus.failed)
          _ErrorCallout(
              message: state.error ?? 'Unable to generate fix proposal.'),
        const SizedBox(height: 10),
        ActionButton(
          label: 'Review ke liye bhejo',
          icon: Icons.rate_review_outlined,
          primary: true,
          loading: state.status == FixProposalStatus.generating,
          onPressed: null,
        ),
      ],
    );
  }

  String get _statusLabel {
    return switch (state.status) {
      FixProposalStatus.idle => 'WAITING',
      FixProposalStatus.generating => 'GENERATING PROPOSAL',
      FixProposalStatus.received => 'FIX READY',
      FixProposalStatus.failed => 'PROPOSAL FAILED',
    };
  }
}

class _FixProposalResultView extends StatelessWidget {
  const _FixProposalResultView({
    required this.result,
    required this.diagnosis,
    required this.prCreation,
    required this.onCreatePullRequest,
    required this.onViewPullRequest,
    required this.onContinueToChangeWorkflow,
  });

  final FixProposalResult result;
  final DiagnosisResult? diagnosis;
  final PrCreationState prCreation;
  final VoidCallback onCreatePullRequest;
  final VoidCallback onViewPullRequest;
  final VoidCallback onContinueToChangeWorkflow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(label: 'FIX READY', tone: _success),
        const SizedBox(height: 12),
        Text(
          result.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(result.summary,
            style: const TextStyle(
                color: _ink, height: 1.35, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        MetricTile(
          label: 'Affected file',
          value:
              result.affectedFiles.isEmpty ? '-' : result.affectedFiles.first,
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 10),
        _ProposalField(
            label: 'ROOT CAUSE',
            value: diagnosis?.rootCause ?? 'Diagnosis not available.'),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.difference_outlined, color: _accent),
              title: const Text('Compact diff',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Review before PR',
                  style: TextStyle(color: _muted, fontSize: 12)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _DiffText(diff: result.diff),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ProposalField(label: 'WHY THIS FIX', value: result.reasoning),
        MetricTile(
            label: 'Confidence',
            value: '${result.confidence}%',
            icon: Icons.query_stats),
        const SizedBox(height: 10),
        StatusBadge(
            label: 'RISK ${_riskLevel(result.risk)}',
            tone: _riskTone(result.risk)),
        const SizedBox(height: 6),
        Text(result.risk, style: const TextStyle(color: _muted, height: 1.35)),
        const SizedBox(height: 10),
        _ProposalField(
            label: 'EXPECTED OUTCOME', value: result.expectedOutcome),
        const Text(
          'VALIDATION PLAN',
          style: TextStyle(
              color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        ...(result.validationPlan.isEmpty
                ? const ['Review the proposal before any action.']
                : result.validationPlan)
            .map((step) => _CheckRow(
                label: step, icon: Icons.check_circle, color: _success)),
        const SizedBox(height: 10),
        _PrCreationPanel(
          state: prCreation,
          onCreatePullRequest: onCreatePullRequest,
          onViewPullRequest: onViewPullRequest,
          onContinueToChangeWorkflow: onContinueToChangeWorkflow,
        ),
      ],
    );
  }

  String _riskLevel(String risk) {
    final upper = risk.toUpperCase();
    if (upper.startsWith('LOW')) return 'LOW';
    if (upper.startsWith('HIGH')) return 'HIGH';
    return 'MEDIUM';
  }

  Color _riskTone(String risk) {
    final level = _riskLevel(risk);
    if (level == 'LOW') return _success;
    if (level == 'HIGH') return _danger;
    return _warning;
  }
}

class _PrCreationPanel extends StatelessWidget {
  const _PrCreationPanel({
    required this.state,
    required this.onCreatePullRequest,
    required this.onViewPullRequest,
    required this.onContinueToChangeWorkflow,
  });

  final PrCreationState state;
  final VoidCallback onCreatePullRequest;
  final VoidCallback onViewPullRequest;
  final VoidCallback onContinueToChangeWorkflow;

  @override
  Widget build(BuildContext context) {
    if (state.status == PrCreationStatus.created && state.result != null) {
      return _PrCreatedView(
        result: state.result!,
        onViewPullRequest: onViewPullRequest,
        onContinueToChangeWorkflow: onContinueToChangeWorkflow,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(label: _statusLabel),
        const SizedBox(height: 10),
        if (state.isCreating) const LinearProgressIndicator(minHeight: 2),
        if (state.status == PrCreationStatus.failed)
          _ErrorCallout(
              message: state.error ?? 'Unable to create GitHub pull request.'),
        const SizedBox(height: 10),
        ActionButton(
          label: 'Review ke liye bhejo',
          icon: Icons.rate_review_outlined,
          primary: true,
          loading: state.isCreating,
          onPressed: state.isCreating ? null : onCreatePullRequest,
        ),
      ],
    );
  }

  String get _statusLabel {
    return switch (state.status) {
      PrCreationStatus.readyToReview => 'READY TO REVIEW',
      PrCreationStatus.creatingBranch => 'CREATING BRANCH',
      PrCreationStatus.creatingCommit => 'CREATING COMMIT',
      PrCreationStatus.openingPullRequest => 'OPENING PULL REQUEST',
      PrCreationStatus.created => 'PR CREATED',
      PrCreationStatus.failed => 'PR CREATION FAILED',
    };
  }
}

class _PrCreatedView extends StatelessWidget {
  const _PrCreatedView({
    required this.result,
    required this.onViewPullRequest,
    required this.onContinueToChangeWorkflow,
  });

  final PrCreationResult result;
  final VoidCallback onViewPullRequest;
  final VoidCallback onContinueToChangeWorkflow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(label: 'PR CREATED', tone: _success),
        const SizedBox(height: 10),
        MetricTile(
            label: 'Repository',
            value: result.repository,
            icon: Icons.source_outlined),
        const SizedBox(height: 8),
        MetricTile(
            label: 'Branch',
            value: result.branch,
            icon: Icons.account_tree_outlined),
        const SizedBox(height: 8),
        MetricTile(
            label: 'PR',
            value: '#${result.prNumber}',
            icon: Icons.rate_review_outlined),
        const SizedBox(height: 8),
        MetricTile(
            label: 'Base', value: result.base, icon: Icons.merge_type_outlined),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionButton(
              label: 'Open PR',
              icon: Icons.open_in_new,
              primary: true,
              onPressed: onViewPullRequest,
            ),
            ActionButton(
              label: 'Govern dekho',
              icon: Icons.arrow_forward,
              onPressed: onContinueToChangeWorkflow,
            ),
          ],
        ),
      ],
    );
  }
}

class _DiffText extends StatelessWidget {
  const _DiffText({required this.diff});

  final String diff;

  @override
  Widget build(BuildContext context) {
    final lines =
        diff.trim().isEmpty ? const ['No diff returned.'] : diff.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.take(80).map((line) {
        final added = line.startsWith('+') && !line.startsWith('+++');
        final removed = line.startsWith('-') && !line.startsWith('---');
        final color = added
            ? const Color(0xFF8CE99A)
            : removed
                ? const Color(0xFFFFA8A8)
                : const Color(0xFFE5E7EB);
        return Text(
          line,
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.35,
          ),
        );
      }).toList(),
    );
  }
}

class _ProposalField extends StatelessWidget {
  const _ProposalField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _DiagnosisResultView extends StatelessWidget {
  const _DiagnosisResultView({required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiagnosisField(label: 'ROOT CAUSE', value: result.rootCause),
        MetricTile(
            label: 'Confidence',
            value: '${result.confidence}%',
            icon: Icons.query_stats),
        const SizedBox(height: 10),
        const Text(
          'SUPPORTING EVIDENCE',
          style: TextStyle(
              color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        ...(result.evidence.isEmpty
                ? const ['No supporting evidence returned.']
                : result.evidence)
            .map((item) => _CheckRow(
                label: item, icon: Icons.check_circle, color: _success)),
        _DiagnosisField(label: 'ALTERNATIVE', value: result.alternativeCause),
        _DiagnosisField(label: 'RISK', value: result.risk),
        _DiagnosisField(label: 'RECOMMENDATION', value: result.recommendation),
        if (result.affectedFiles.isNotEmpty) ...[
          const Text(
            'AFFECTED FILES',
            style: TextStyle(
                color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.affectedFiles
                .map((file) => StatusBadge(label: file, tone: _accent))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _DiagnosisField extends StatelessWidget {
  const _DiagnosisField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _RagResultCard extends StatelessWidget {
  const _RagResultCard({required this.result});

  final RagContextResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(result.source,
              style: const TextStyle(color: _accent, fontSize: 12)),
          const SizedBox(height: 8),
          Text(result.excerpt,
              style: const TextStyle(color: _ink, height: 1.35)),
          const SizedBox(height: 10),
          StatusBadge(
              label: 'Relevance ${result.score.toStringAsFixed(3)}',
              tone: _accent),
        ],
      ),
    );
  }
}

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.1),
        border: Border.all(color: _danger.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _Subsection extends StatelessWidget {
  const _Subsection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SkeletonBox(height: 118),
        SizedBox(height: 12),
        _SkeletonBox(height: 96),
        SizedBox(height: 12),
        _SkeletonBox(height: 180),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class ReplayTrace extends StatelessWidget {
  const ReplayTrace({super.key, required this.title, required this.fixed});

  final String title;
  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Tap Login', true),
      ('Open Dashboard', true),
      ('Open Settings', true),
      ('Rotate Device', true),
      (fixed ? 'Crash not reproduced' : 'Crash', fixed),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) {
            final passed = row.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(passed ? Icons.check : Icons.close,
                      color: passed ? _success : _danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(row.$1)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ApprovalChecklist extends StatelessWidget {
  const ApprovalChecklist({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'APPROVAL_REQUIRED' || status == 'RECOVERED';
    final recovered = status == 'RECOVERED';
    final rows = [
      ('PR created', verified || recovered),
      ('CI passed', verified || recovered),
      ('Security checks passed', verified || recovered),
      ('Code review complete', recovered),
      ('Change manager approval', recovered),
    ];
    return Column(
      children: rows.map((row) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            row.$2 ? Icons.check_circle : Icons.hourglass_bottom,
            color: row.$2 ? _success : _warning,
          ),
          title: Text(row.$1),
        );
      }).toList(),
    );
  }
}

class ChangeGatePanel extends StatelessWidget {
  const ChangeGatePanel({
    super.key,
    required this.state,
    required this.onEvaluate,
    required this.onDemoApproval,
  });

  final ChangeGateState state;
  final VoidCallback onEvaluate;
  final VoidCallback onDemoApproval;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHANGE GOVERNANCE',
          style: TextStyle(
              color: _muted, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (state.status == ChangeGateStatus.evaluating)
          const LinearProgressIndicator(minHeight: 2),
        if (state.status == ChangeGateStatus.failed)
          _ErrorCallout(
              message: state.error ?? 'Unable to evaluate change gate.'),
        if (result == null && state.status != ChangeGateStatus.evaluating)
          const Text(
            'PR banao, phir GitHub facts aur OneOps policy evaluate hogi.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
        if (result != null) ...[
          _GovernanceFacts(result: result),
          const SizedBox(height: 12),
          StatusBadge(
              label: result.finalState.replaceAll('_', ' '),
              tone: result.eligible ? _success : _warning),
          const SizedBox(height: 8),
          ...result.reasons.map((reason) => _CheckRow(
                label: reason,
                icon: _reasonIcon(reason),
                color: _reasonColor(reason),
              )),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionButton(
              label: 'Gate evaluate karo',
              icon: Icons.policy_outlined,
              primary: result == null,
              loading: state.status == ChangeGateStatus.evaluating,
              onPressed: state.status == ChangeGateStatus.evaluating
                  ? null
                  : onEvaluate,
            ),
            ActionButton(
              label: 'ONEOPS DEMO APPROVAL',
              icon: Icons.how_to_reg_outlined,
              loading: state.status == ChangeGateStatus.evaluating,
              onPressed: state.status == ChangeGateStatus.evaluating
                  ? null
                  : onDemoApproval,
            ),
          ],
        ),
      ],
    );
  }

  IconData _reasonIcon(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('required') ||
        lower.contains('must') ||
        lower.contains('unknown')) {
      return Icons.hourglass_bottom;
    }
    return Icons.check_circle;
  }

  Color _reasonColor(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('required') ||
        lower.contains('must') ||
        lower.contains('unknown')) {
      return _warning;
    }
    return _success;
  }
}

class _GovernanceFacts extends StatelessWidget {
  const _GovernanceFacts({required this.result});

  final ChangeGateResult result;

  @override
  Widget build(BuildContext context) {
    final pr = result.pr;
    final demoApproval = pr.reviewSource == 'OneOps Demo Approval';
    final approvalLabel =
        demoApproval ? 'ONEOPS DEMO APPROVAL' : 'Human approval baaki';
    final approvalDetail = demoApproval
        ? 'prototype-only; ${pr.approvingReviews} real GitHub approvals'
        : '${pr.approvingReviews}/${pr.requiredApprovals} GitHub approvals; ${pr.reviewDecision}';
    final policyLabel =
        result.checks.policySatisfied ? 'Policy Satisfied' : 'Policy Blocked';
    final policyIcon =
        result.checks.policySatisfied ? Icons.check_circle : Icons.lock;
    final policyColor = result.checks.policySatisfied ? _success : _warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PR #${pr.prNumber}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _GateRow(
            label: 'GitHub PR', passed: result.checks.prOpen, detail: pr.state),
        _GateRow(
            label: 'Targets main',
            passed: result.checks.targetsMain,
            detail: pr.baseBranch),
        _GateRow(
            label: 'CI passed',
            passed: result.checks.ciPassed,
            detail: '${pr.ciStatus} via ${pr.ciSource}'),
        _GateRow(
          label: approvalLabel,
          passed: result.checks.humanApproval,
          detail: approvalDetail,
        ),
        _GateRow(
          label: policyLabel,
          passed: result.checks.policySatisfied,
          detail: demoApproval
              ? 'prototype-only; no merge, deploy, or protection bypass'
              : 'human yes ke bina execute nahi hoga',
          icon: policyIcon,
          color: policyColor,
        ),
      ],
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({
    required this.label,
    required this.passed,
    this.detail,
    this.icon,
    this.color,
  });

  final String label;
  final bool passed;
  final String? detail;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? (passed ? Icons.check_circle : Icons.hourglass_bottom),
              color: color ?? (passed ? _success : _warning), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  detail ?? (passed ? 'passed' : 'blocked'),
                  style: const TextStyle(color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentMemoryCard extends StatelessWidget {
  const IncidentMemoryCard({super.key, required this.incident});

  final Incident? incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Green dependency regression',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            incident?.status == 'RECOVERED'
                ? 'Verified fix stored with MTTR ${incident?.mttr}. Agli baar yeh context kaam aayega.'
                : 'Recovery complete hote hi verified learning yahan save hogi.',
            style: const TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          const StatusBadge(label: 'Similarity 86%', tone: _accent),
        ],
      ),
    );
  }
}
