import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  final AppState state;
  final VoidCallback onGoToPlayers;

  const HomeTab({
    super.key,
    required this.state,
    required this.onGoToPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final activeMatches = state.activeMatches;
    final finishedMatches = state.finishedMatches;
    final waitingPlayers = state.waitingPlayers;
    final notCheckedIn = state.notCheckedInPlayers;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    if (isDesktop || isTablet) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLiveCourtsHeader(activeMatches.length),
                      const SizedBox(height: 18),
                      if (activeMatches.isEmpty)
                        _buildEmptyLiveCourts()
                      else
                        ...activeMatches.map((m) => _buildLiveCourtCard(m, context)),
                      const SizedBox(height: 20),
                      _buildShuffleActionButton(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWaitingQueueCard(waitingPlayers),
                      if (notCheckedIn.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildCheckInNudge(notCheckedIn.length),
                      ],
                      if (finishedMatches.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildRecentMatchesCard(finishedMatches),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLiveCourtsHeader(activeMatches.length),
          const SizedBox(height: 16),
          if (activeMatches.isEmpty)
            _buildEmptyLiveCourts()
          else
            ...activeMatches.map((m) => _buildLiveCourtCard(m, context)),
          const SizedBox(height: 16),
          _buildShuffleActionButton(),
          const SizedBox(height: 24),
          _buildWaitingQueueCard(waitingPlayers),
          if (notCheckedIn.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCheckInNudge(notCheckedIn.length),
          ],
          if (finishedMatches.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildRecentMatchesCard(finishedMatches),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLiveCourtsHeader(int count) {
    return Row(
      children: [
        const _PulseDot(),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.darkGreen, AppColors.emerald],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "Live Courts",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: count > 0 ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            "$count Active",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: count > 0 ? AppColors.emerald : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLiveCourts() {
    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.border, radius: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.backgroundCanvas,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: const Icon(Icons.sports_tennis_rounded, size: 48, color: AppColors.emeraldLight),
            ),
            const SizedBox(height: 20),
            const Text(
              "No active matches right now",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the Shuffle Match button below to pair players and start a new match.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCourtCard(dynamic m, BuildContext context) {
    final draft = state.scoreDrafts[m.id] ?? {'a': '', 'b': ''};
    final teamANames = m.teamA.map((id) => state.byId[id]?.name ?? '').join(" & ");
    final teamBNames = m.teamB.map((id) => state.byId[id]?.name ?? '').join(" & ");
    final canSubmit = (draft['a']?.isNotEmpty ?? false) && (draft['b']?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecorations.modernCard(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: AppColors.darkGreenGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stadium_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "COURT ${m.court}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "PLAYING",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teamANames,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildCleanScoreInput(
                      value: draft['a'] ?? '',
                      onChanged: (val) => state.setDraftScore(m.id, 'a', val),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCanvas,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "VS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teamBNames,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildCleanScoreInput(
                      value: draft['b'] ?? '',
                      onChanged: (val) => state.setDraftScore(m.id, 'b', val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? () => state.submitScore(m.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      disabledBackgroundColor: AppColors.surfaceSecondary,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Submit Score",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShuffleActionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.emerald],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => state.setShuffleOpen(true),
        icon: const Icon(Icons.shuffle_rounded, size: 22, color: Colors.white),
        label: const Text(
          "Shuffle Match",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingQueueCard(List<dynamic> waitingPlayers) {
    return Container(
      decoration: AppDecorations.modernCard(borderRadius: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Waiting Queue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${waitingPlayers.length} ready",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (waitingPlayers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No players waiting in queue.",
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: waitingPlayers.map((p) {
                return Material(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => state.setSelectedPlayerId(p.id),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      padding: const EdgeInsets.only(left: 14, right: 8, top: 8, bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.backgroundCanvas,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${p.played}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckInNudge(int notCheckedCount) {
    return Material(
      color: const Color(0xFFFFFBEB), // Soft amber tint
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onGoToPlayers,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.amberBadge.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amberBadge.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded, size: 20, color: AppColors.amberBadge),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "$notCheckedCount player${notCheckedCount == 1 ? '' : 's'} not checked in",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberBadge,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.amberBadge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMatchesCard(List<dynamic> finishedMatches) {
    return Container(
      decoration: AppDecorations.modernCard(borderRadius: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Matches",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: finishedMatches.take(5).length,
            separatorBuilder: (context, index) => const Divider(height: 24, color: AppColors.borderSubtle, thickness: 1),
            itemBuilder: (context, index) {
              final m = finishedMatches[index];
              final teamANames = m.teamA.map((id) => state.byId[id]?.name ?? '').join(" & ");
              final teamBNames = m.teamB.map((id) => state.byId[id]?.name ?? '').join(" & ");

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCanvas,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "C${m.court}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: teamANames, style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                            text: "  ${m.scoreA} – ${m.scoreB}  ",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emerald,
                            ),
                          ),
                          TextSpan(text: teamBNames, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCleanScoreInput({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: 56,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value.isNotEmpty ? AppColors.emerald : AppColors.border, width: value.isNotEmpty ? 2 : 1),
        boxShadow: value.isNotEmpty
            ? [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.15), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            ),
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.darkGreen,
          ),
          decoration: const InputDecoration(
            hintText: "–",
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.emerald,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth = 1.5;
  final double radius;

  _DashedBorderPainter({required this.color, this.radius = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));
    
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? 6.0 : 4.0;
        if (draw) {
          dashPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
