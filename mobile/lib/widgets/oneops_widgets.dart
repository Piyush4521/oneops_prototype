import 'package:flutter/material.dart';

import '../models/code_context.dart';
import '../models/incident_state.dart';

const _surface = Color(0xFF111720);
const _surfaceSoft = Color(0xFF161E28);
const _border = Color(0xFF273242);
const _accent = Color(0xFF7BC7C0);
const _success = Color(0xFF41D38B);
const _warning = Color(0xFFFFC857);
const _danger = Color(0xFFFF6B6B);
const _muted = Color(0xFF8C98A8);
const _ink = Color(0xFFE7EDF4);

Color statusColor(String status) {
  if (status.contains('RECOVERED') || status.contains('VERIFIED')) {
    return _success;
  }
  if (status.contains('FAIL') || status.contains('BLOCKED')) return _danger;
  if (status.contains('APPROVAL') || status.contains('REPRODUCING')) {
    return _warning;
  }
  return _accent;
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
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: _muted, fontSize: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: _muted, height: 1.35)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
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
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                active?.id ?? 'ONEOPS',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
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
                tone: _accent,
              ),
              StatusBadge(label: 'API service', tone: const Color(0xFF9FB7FF)),
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
        color: _surfaceSoft,
        border: Border.all(color: _border),
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
                Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: _ink, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: status),
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
            const Text('Confidence', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('$clamped%', style: const TextStyle(color: _accent, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: clamped / 100,
            backgroundColor: _surfaceSoft,
            valueColor: AlwaysStoppedAnimation(statusColor('$clamped VERIFIED')),
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
                    Text(step.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (step.detail.isNotEmpty)
                      Text(step.detail, style: const TextStyle(color: _muted, fontSize: 12)),
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
    final body = text.contains(':') ? text.substring(text.indexOf(':') + 1) : text;
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
            style: TextStyle(color: tone, fontSize: 11, fontWeight: FontWeight.w900),
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
        label: Text(label),
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
      label: Text(label),
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
                child: Text('Candidate change', style: TextStyle(fontWeight: FontWeight.w900)),
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
                      style: const TextStyle(fontFamily: 'monospace', height: 1.35),
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
    final verified = status == 'VERIFIED_FIX_READY' || status == 'APPROVAL_REQUIRED' || status == 'RECOVERED';
    final rows = [
      ('Office Kit bridge', 'Placeholder ready', false),
      ('Workstation', 'Connected through backend', true),
      ('Docker sandbox', reproducing ? 'Testing' : verified ? 'Completed' : 'Waiting', reproducing || verified),
      ('Verification', verified ? 'Completed' : 'Blocked until reproduction', verified),
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
              border: Border.all(color: active ? _accent.withValues(alpha: 0.45) : _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? _success : _muted),
                const SizedBox(width: 10),
                Expanded(child: Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(row.$2, style: const TextStyle(color: _muted, fontSize: 12)),
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
              title: const Text('View technical logs', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Short operational summary only', style: TextStyle(color: _muted, fontSize: 12)),
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
                    style: const TextStyle(fontFamily: 'monospace', color: _muted, height: 1.4),
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
      title: 'Ask for code context',
      subtitle: 'Relevant file only, repository stays private',
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
            label: 'Potentially affected',
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
              children: request.scope.map((item) => StatusBadge(label: item, tone: _accent)).toList(),
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
                    'Only the relevant context is requested. The full repository is not exposed.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (state.status == CodeContextStatus.received && state.result != null) ...[
            _ReceivedContext(result: state.result!),
            const SizedBox(height: 12),
          ],
          if (state.status == CodeContextStatus.failed && state.error != null) ...[
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
                  label: state.status == CodeContextStatus.failed ? 'Retry code context' : 'Request code context',
                  icon: Icons.code,
                  primary: true,
                  loading: state.status == CodeContextStatus.requesting,
                  onPressed: available ? (state.status == CodeContextStatus.failed ? onRetry : onRequest) : null,
                ),
              ActionButton(
                label: 'Continue to proposed fix',
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
      CodeContextStatus.idle => available ? 'Potential cause identified' : 'Investigation required first',
      CodeContextStatus.requesting => 'Requesting relevant code...',
      CodeContextStatus.received => 'Code context received',
      CodeContextStatus.failed => 'Code context request failed',
      CodeContextStatus.cancelled => 'Code context request cancelled',
    };
  }

  String get _message {
    return switch (state.status) {
      CodeContextStatus.idle => available
          ? 'OneOps can now request the smallest useful code context for diagnosis.'
          : 'Run investigation before requesting component-level code context.',
      CodeContextStatus.requesting => 'Fetching read-only context through the OneOps backend.',
      CodeContextStatus.received => 'The requested file context is available for the proposed fix review.',
      CodeContextStatus.failed => 'No code context was attached. Retry when the workspace is available.',
      CodeContextStatus.cancelled => 'No repository data was requested after cancellation.',
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
              Text('CODE CONTEXT RECEIVED', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          MetricTile(label: 'Repository', value: result.repository, icon: Icons.storage_outlined),
          const SizedBox(height: 8),
          MetricTile(label: 'Path', value: result.path, icon: Icons.description_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: MetricTile(label: 'Branch', value: result.ref, icon: Icons.account_tree_outlined)),
              const SizedBox(width: 8),
              Expanded(child: MetricTile(label: 'Commit', value: _shortCommit(result.commit), icon: Icons.commit)),
            ],
          ),
          const SizedBox(height: 8),
          MetricTile(label: 'Source', value: result.source, icon: Icons.source_outlined),
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
                title: const Text('Source preview', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(result.fileName, style: const TextStyle(color: _muted, fontSize: 12)),
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
                      style: const TextStyle(fontFamily: 'monospace', color: _ink, height: 1.35),
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
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) {
            final passed = row.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(passed ? Icons.check : Icons.close, color: passed ? _success : _danger, size: 18),
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
          const Text('Green dependency regression', style: TextStyle(fontWeight: FontWeight.w900)),
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
