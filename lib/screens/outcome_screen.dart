import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crisis_models.dart';
import '../providers/crisis_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OutcomeScreen extends StatefulWidget {
  const OutcomeScreen({super.key});

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _confidenceBarController;
  late Animation<double> _confidenceBarAnimation;
  final ScrollController _auditScrollController = ScrollController();
  bool _animInitialized = false;
  late PipelineResult pipelineResult;

  @override
  void initState() {
    super.initState();
    _confidenceBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceBarAnimation = Tween<double>(begin: 0, end: 0).animate(_confidenceBarController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      final result = context.read<CrisisProvider>().result;
      final confidence = result?.crisisEvent?.confidence ?? 0;
      _confidenceBarAnimation = Tween<double>(begin: 0, end: confidence / 100).animate(
        CurvedAnimation(parent: _confidenceBarController, curve: Curves.easeOutCubic),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confidenceBarController.forward();
        if (_auditScrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_auditScrollController.hasClients) {
              _auditScrollController.animateTo(
                _auditScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _confidenceBarController.dispose();
    _auditScrollController.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    pipelineResult = context.watch<CrisisProvider>().result!;
    final crisis = pipelineResult.crisisEvent;
    final emoji = crisis != null ? AppTheme.crisisEmoji(crisis.crisisType) : '🚨';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ═══════════ 1. CUSTOM APPBAR ═══════════
          _buildAppBar(context),

          // ═══════════ SCROLLABLE CONTENT ═══════════
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                // ═══════════ 2. CRISIS HEADER CARD ═══════════
                _buildCrisisHeader(crisis, emoji),
                const SizedBox(height: 24),

                // ═══════════ 3. SYSTEM STATE COMPARISON ═══════════
                _buildSectionLabel('SYSTEM STATE TRANSFORMATION'),
                const SizedBox(height: 12),
                _buildStateComparison(),
                const SizedBox(height: 24),

                // ═══════════ 4. EXECUTED ACTIONS TIMELINE ═══════════
                _buildActionsHeader(),
                const SizedBox(height: 12),
                _buildActionsTimeline(),
                const SizedBox(height: 24),

                // ═══════════ 5. AUDIT LOG ═══════════
                _buildAuditHeader(),
                const SizedBox(height: 12),
                _buildAuditLog(),
              ],
            ),
          ),
        ],
      ),

      // ═══════════ 6. SHARE / EXPORT BUTTON ═══════════
      bottomSheet: _buildExportButton(context),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  1. CUSTOM APPBAR                                    ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.crimsonDark, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('📊 ', style: TextStyle(fontSize: 16)),
                const Expanded(
                  child: Text(
                    'CRISIS INTELLIGENCE REPORT',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.border.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentTime(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  2. CRISIS HEADER CARD                               ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildCrisisHeader(CrisisEvent? crisis, String emoji) {
    final confidence = crisis?.confidence ?? 0;

    return GlowCard(
      glowColor: AppTheme.crimson,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + severity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crisis?.crisisType.toUpperCase() ?? 'UNKNOWN CRISIS',
                      style: const TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (crisis != null) SeverityBadge(severity: crisis.severity),
                        if (crisis != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${confidence.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  crisis?.location ?? 'Unknown location',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confidence meter
          const Text(
            'AI CONFIDENCE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _confidenceBarAnimation,
            builder: (context, child) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _confidenceBarAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [AppTheme.crimsonDark, AppTheme.crimson],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(_confidenceBarAnimation.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Affected population
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Est. ${crisis?.affectedPopulation ?? '0'} affected',
                style: const TextStyle(
                  color: AppTheme.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Situation assessment box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF060911),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: AppTheme.crimson, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SITUATION ASSESSMENT',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  crisis?.situationSummary ?? 'No assessment available.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  3. SYSTEM STATE COMPARISON                          ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildStateComparison() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BEFORE
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.crimson.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEFORE',
                  style: TextStyle(
                    color: AppTheme.crimson,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...pipelineResult.systemStateBefore.entries.map((e) => _stateRow(
                      e.key,
                      e.value.toString(),
                      valueColor: AppTheme.textPrimary,
                    )),
                if (pipelineResult.systemStateBefore.isEmpty)
                  const Text('No initial state', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // AFTER
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.emerald.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AFTER',
                  style: TextStyle(
                    color: AppTheme.emerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...pipelineResult.systemStateAfter.entries.map((e) => _stateRow(
                      e.key,
                      e.value.toString(),
                      valueColor: AppTheme.emerald,
                    )),
                if (pipelineResult.systemStateAfter.isEmpty)
                  const Text('No final state', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stateRow(String key, String value, {required Color valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  4. EXECUTED ACTIONS TIMELINE                        ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildActionsHeader() {
    return Row(
      children: [
        _buildSectionLabel('RESPONSE ACTIONS EXECUTED'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.crimsonGlow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${pipelineResult.executedActions.length}',
            style: const TextStyle(
              color: AppTheme.crimson,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsTimeline() {
    if (pipelineResult.executedActions.isEmpty) {
      return GlowCard(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No actions were executed in this pipeline run.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return Column(
      children: pipelineResult.executedActions.asMap().entries.map((entry) {
        final idx = entry.key;
        final action = entry.value;
        final isLast = idx == pipelineResult.executedActions.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline bar
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.emerald,
                        border: Border.all(color: AppTheme.emerald, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emerald.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 8),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppTheme.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Action card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlowCard(
                    glowColor: AppTheme.emerald,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + SUCCESS badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                action.actionName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const StatusChip(label: '✓ SUCCESS', color: AppTheme.emerald),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Timestamp
                        Text(
                          action.timestamp.isNotEmpty ? action.timestamp : 'T+${idx * 2}s',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Before / After
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF060911),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'WAS: ',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      action.beforeState,
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text('  →', style: TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'NOW: ',
                                    style: TextStyle(
                                      color: AppTheme.emerald,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      action.afterState,
                                      style: const TextStyle(color: AppTheme.emerald, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  5. AUDIT LOG                                        ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildAuditHeader() {
    return Row(
      children: [
        const Icon(Icons.terminal, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 6),
        _buildSectionLabel('AUDIT TRAIL'),
      ],
    );
  }

  Widget _buildAuditLog() {
    if (pipelineResult.auditLog.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF040710),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.emerald.withOpacity(0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.terminal, color: AppTheme.textMuted.withOpacity(0.5), size: 28),
            const SizedBox(height: 8),
            const Text(
              '> Awaiting audit trail entries...',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF040710),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.emerald.withOpacity(0.3), width: 1),
      ),
      child: ListView.builder(
        controller: _auditScrollController,
        itemCount: pipelineResult.auditLog.length,
        itemBuilder: (context, index) {
          final log = pipelineResult.auditLog[index];
          final ts = index.toString().padLeft(2, '0');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
                children: [
                  TextSpan(
                    text: '[10:15:$ts] ',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const TextSpan(
                    text: '► ',
                    style: TextStyle(color: AppTheme.terminalGreen, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: log,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ╔═══════════════════════════════════════════════════════╗
  // ║  6. EXPORT BUTTON                                    ║
  // ╚═══════════════════════════════════════════════════════╝
  Widget _buildExportButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppTheme.crimson, AppTheme.crimsonDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final reportId = (Random().nextInt(9000) + 1000).toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.surface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                content: Text(
                  'Report #RAHAT-$reportId saved to system',
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.share, color: Colors.white, size: 18),
          label: const Text(
            'EXPORT CRISIS REPORT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
