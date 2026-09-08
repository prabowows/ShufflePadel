import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RankingTab extends StatelessWidget {
  final AppState state;

  const RankingTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final ranked = state.ranked;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final filters = [
      {'key': 'points', 'label': 'Points (PTS)'},
      {'key': 'wins', 'label': 'Total Wins'},
      {'key': 'winRate', 'label': 'Win Rate (%)'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 24,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: filters.map((f) {
                      final isActive = state.rankFilter == f['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => state.setRankFilter(f['key']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.darkGreen : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isActive ? AppColors.darkGreen : AppColors.border,
                                width: isActive ? 2 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.darkGreen.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              f['label']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                color: isActive ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (isDesktop)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Text(
                        "Formula: PTS = 3×Wins + Game Difference",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              if (!isDesktop) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCanvas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Formula: PTS = 3×Wins + Game Difference",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              if (isDesktop && ranked.length >= 3) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _buildPodiumCard(ranked[1], 2, AppColors.silver, height: 160)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPodiumCard(ranked[0], 1, AppColors.gold, isLeader: true, height: 190)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPodiumCard(ranked[2], 3, AppColors.bronze, height: 150)),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              Container(
                decoration: AppDecorations.modernCard(borderRadius: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ranked.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSubtle,
                  ),
                  itemBuilder: (context, index) {
                    final p = ranked[index];
                    final isTop3 = index < 3;
                    final rankColor = index == 0 ? AppColors.gold : index == 1 ? AppColors.silver : index == 2 ? AppColors.bronze : AppColors.textSecondary;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => state.setSelectedPlayerId(p.id),
                        hoverColor: AppColors.backgroundCanvas,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isTop3
                                      ? rankColor.withValues(alpha: 0.1)
                                      : AppColors.backgroundCanvas,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isTop3
                                        ? rankColor.withValues(alpha: 0.3)
                                        : AppColors.border,
                                    width: isTop3 ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isTop3 ? rankColor : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${p.played} played · ${p.wins}W ${p.losses}L (Diff: ${p.diff > 0 ? '+' : ''}${p.diff})",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isDesktop) ...[
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${p.winRate}% Win Rate",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          height: 8,
                                          color: AppColors.surfaceSecondary,
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: p.winRate / 100,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.darkGreen, AppColors.emerald],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    state.rankFilter == "winRate"
                                        ? "${p.winRate}%"
                                        : state.rankFilter == "wins"
                                            ? "${p.wins}"
                                            : "${p.points}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                  Text(
                                    state.rankFilter == "winRate"
                                        ? "RATE"
                                        : state.rankFilter == "wins"
                                            ? "WINS"
                                            : "PTS",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumCard(Player player, int rank, Color accentColor, {bool isLeader = false, double height = 160}) {
    return GestureDetector(
      onTap: () => state.setSelectedPlayerId(player.id),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isLeader ? null : Colors.white,
          gradient: isLeader ? AppColors.darkGreenGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: isLeader
              ? null
              : Border(
                  top: BorderSide(color: accentColor, width: 4),
                  bottom: const BorderSide(color: AppColors.border),
                  left: const BorderSide(color: AppColors.border),
                  right: const BorderSide(color: AppColors.border),
                ),
          boxShadow: [
            BoxShadow(
              color: (isLeader ? AppColors.darkGreen : Colors.black).withValues(alpha: isLeader ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLeader)
              const Text("🏆", style: TextStyle(fontSize: 32))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Rank #$rank",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isLeader ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${player.points} PTS · ${player.winRate}% win rate",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLeader ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
