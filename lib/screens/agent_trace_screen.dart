import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crisis_models.dart';
import '../providers/crisis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AgentTraceScreen extends StatefulWidget {
  const AgentTraceScreen({super.key});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> with TickerProviderStateMixin {
  // Blinker for LIVE dot
  late AnimationController _blinkerController;

  // Per-step fade+slide controllers
  final List<AnimationController> _stepControllers = [];
  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];
  bool _animationsBuilt = false;

  @override
  void initState() {
    super.initState();
    _blinkerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  void _buildStepAnimations(int totalSteps) {
    if (_animationsBuilt) return;
    _animationsBuilt = true;

    for (int i = 0; i < totalSteps; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.15, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

      _stepControllers.add(controller);
      _fadeAnims.add(fade);
      _slideAnims.add(slide);

      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _blinkerController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Flatten all steps across all 4 agents for global indexing ──
  List<String> _flattenSteps(PipelineResult r) {
    return [
      ..._signalSteps(r),
      ..._detectorSteps(r),
      ..._plannerSteps(r),
      ..._executorSteps(r),
    ];
  }

  List<String> _signalSteps(PipelineResult r) => [
        'Initializing multi-source signal ingestion...',
        'Extracted ${r.signals.length} valid signals from input feeds.',
      ];

  List<String> _detectorSteps(PipelineResult r) =>
      r.crisisEvent?.reasoningSteps ??
      ['Analyzing signals for spatial clustering...', 'No distinct crisis pattern identified.'];

  List<String> _plannerSteps(PipelineResult r) => [
        'Querying resource dispatch pools & severity matrix...',
        'Generated ${r.actions.length} prioritized action plans.',
      ];

  List<String> _executorSteps(PipelineResult r) => [
        'Starting action execution simulation...',
        'Executing ${r.executedActions.length} state transitions.',
        'System state updated. Audit log finalized.',
      ];

  int _globalOffset(int agentIndex, PipelineResult r) {
    final groups = [_signalSteps(r), _detectorSteps(r), _plannerSteps(r), _executorSteps(r)];
    int offset = 0;
    for (int i = 0; i < agentIndex; i++) {
      offset += groups[i].length;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrisisProvider>(
      builder: (context, provider, child) {
        final result = provider.result!;
        final allSteps = _flattenSteps(result);
        _buildStepAnimations(allSteps.length);

        final bool hasSignals = result.signals.isNotEmpty;
        final bool hasCrisis = result.crisisEvent != null;
        final bool hasActions = result.actions.isNotEmpty;
        final bool hasExecuted = result.executedActions.isNotEmpty;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              // ═══════════ 1. CUSTOM APPBAR ═══════════
              _buildAppBar(context),

              // ═══════════ 2. PIPELINE PROGRESS BAR ═══════════
              _buildPipelineBar(hasSignals, hasCrisis, hasActions, hasExecuted),

              // ═══════════ 3–4. SCROLLABLE CONTENT ═══════════
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // Agent cards
                    _buildAgentCard(
                      name: 'Signal Collector',
                      emoji: '📡',
                      steps: _signalSteps(result),
                      globalStart: _globalOffset(0, result),
                      isComplete: hasSignals,
                      glowColor: hasSignals ? AppTheme.emeraldGlow : null,
                    ),
                    _buildAgentCard(
                      name: 'Crisis Detector',
                      emoji: '🔍',
                      steps: _detectorSteps(result),
                      globalStart: _globalOffset(1, result),
                      isComplete: hasCrisis,
                      glowColor: hasCrisis ? AppTheme.emeraldGlow : AppTheme.electricGlow,
                      confidence: result.crisisEvent?.confidence,
                    ),
                    _buildAgentCard(
                      name: 'Response Planner',
                      emoji: '📋',
                      steps: _plannerSteps(result),
                      globalStart: _globalOffset(2, result),
                      isComplete: hasActions,
                      glowColor: hasActions ? AppTheme.emeraldGlow : null,
                    ),
                    _buildAgentCard(
                      name: 'Action Executor',
                      emoji: '⚡',
                      steps: _executorSteps(result),
                      globalStart: _globalOffset(3, result),
                      isComplete: hasExecuted,
                      glowColor: hasExecuted ? AppTheme.emeraldGlow : null,
                    ),

                    const SizedBox(height: 28),

                    // ═══════════ 4. ACTIONS GENERATED ═══════════
                    Row(
                      children: [
                        const Text(
                          'ACTIONS GENERATED',
                          style: TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.crimsonGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${result.actions.length}',
                            style: const TextStyle(
                              color: AppTheme.crimson,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (result.actions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No actions generated.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),

                    ...result.actions.map((a) => _buildActionCard(a)).toList(),
                  ],
                ),
              ),
            ],
          ),

          // ═══════════ 5. BOTTOM BUTTON ═══════════
          bottomSheet: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      side: const BorderSide(color: AppTheme.electric),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home, color: Colors.white, size: 16),
                    label: const Text(
                      'HOME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/outcome');
                    },
                    child: const Text(
                      'VIEW REPORT →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  1. CUSTOM APPBAR                                    ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.crimsonDark, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                '🤖 ',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'AGENT REASONING TRACE',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _blinkerController,
                child: const PulsingDot(color: AppTheme.emerald, size: 8),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  2. PIPELINE PROGRESS BAR                            ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildPipelineBar(bool s1, bool s2, bool s3, bool s4) {
    final steps = [
      _PipelineStep('📡', 'SIGNAL', s1),
      _PipelineStep('🔍', 'DETECT', s2),
      _PipelineStep('📋', 'PLAN', s3),
      _PipelineStep('⚡', 'EXECUTE', s4),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      color: AppTheme.background,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final leftDone = steps[i ~/ 2].done;
            return Expanded(
              child: Container(
                height: 2,
                color: leftDone ? AppTheme.crimson : AppTheme.border,
              ),
            );
          }
          final step = steps[i ~/ 2];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? AppTheme.crimson : Colors.transparent,
                  border: Border.all(
                    color: step.done ? AppTheme.crimson : AppTheme.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    step.emoji,
                    style: TextStyle(fontSize: step.done ? 14 : 12),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TextStyle(
                  color: step.done ? AppTheme.textPrimary : AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  3. AGENT CARD                                       ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildAgentCard({
    required String name,
    required String emoji,
    required List<String> steps,
    required int globalStart,
    required bool isComplete,
    Color? glowColor,
    double? confidence,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowCard(
        glowColor: glowColor,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (confidence != null && confidence > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonGlow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppTheme.crimson,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                StatusChip(
                  label: isComplete ? 'COMPLETE ✓' : 'RUNNING...',
                  color: isComplete ? AppTheme.emerald : AppTheme.amber,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Terminal block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060911),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border.withOpacity(0.5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.asMap().entries.map((entry) {
                  final localIdx = entry.key;
                  final step = entry.value;
                  final globalIdx = globalStart + localIdx;
                  final ts = localIdx.toString().padLeft(2, '0');

                  Widget line = Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
                        children: [
                          TextSpan(
                            text: '[10:15:$ts] ',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                          const TextSpan(
                            text: '› ',
                            style: TextStyle(color: AppTheme.terminalGreen, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: step,
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );

                  // Animate if controller exists
                  if (globalIdx < _fadeAnims.length) {
                    line = FadeTransition(
                      opacity: _fadeAnims[globalIdx],
                      child: SlideTransition(
                        position: _slideAnims[globalIdx],
                        child: line,
                      ),
                    );
                  }

                  return line;
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  4. ACTION CARD                                      ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildActionCard(ActionItem action) {
    final pColor = AppTheme.priorityColor(action.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left colored border strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: pColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + priority badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              action.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: pColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: pColor.withOpacity(0.3), width: 1),
                            ),
                            child: Text(
                              action.priority.toUpperCase(),
                              style: TextStyle(
                                color: pColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Resource chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.electricGlow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          action.resource,
                          style: const TextStyle(
                            color: AppTheme.electric,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(
                        action.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Action ID
                      Text(
                        'ID: ${action.id}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper data class for pipeline steps
class _PipelineStep {
  final String emoji;
  final String label;
  final bool done;
  _PipelineStep(this.emoji, this.label, this.done);
}
