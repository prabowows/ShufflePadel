import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PlayersTab extends StatefulWidget {
  final AppState state;

  const PlayersTab({
    super.key,
    required this.state,
  });

  @override
  State<PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final TextEditingController _playerController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _handleAdd() {
    final text = _playerController.text.trim();
    if (text.isNotEmpty) {
      widget.state.addPlayer(text);
      _playerController.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    var sortedPlayers = List.of(widget.state.players)
      ..sort((a, b) => a.name.compareTo(b.name));

    if (_searchQuery.isNotEmpty) {
      sortedPlayers = sortedPlayers
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 24,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row: Add Player & Search
              Container(
                decoration: AppDecorations.cleanWhiteCard(borderRadius: 16),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _playerController,
                              onSubmitted: (_) => _handleAdd(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: "New player name...",
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                                prefixIcon: Icon(Icons.person_add_alt_1_rounded, color: AppColors.darkGreen, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.darkGreenGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleAdd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, size: 20),
                                SizedBox(width: 6),
                                Text("Add", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Filter search input & Check in count
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: "Search players...",
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.darkGreenGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkGreen.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "${widget.state.checkedInCount}/${widget.state.players.length} Checked In",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Player List
              Container(
                decoration: AppDecorations.cleanWhiteCard(borderRadius: 16),
                child: sortedPlayers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off_rounded, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                "No players found.",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedPlayers.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 0.8,
                          color: AppColors.borderSubtle,
                        ),
                        itemBuilder: (context, index) {
                          final p = sortedPlayers[index];
                          final isPlaying = p.status == "playing";

                          final statusColor = isPlaying
                              ? AppColors.gold
                              : p.checkedIn
                                  ? AppColors.emerald
                                  : AppColors.textMuted;

                          final statusText = isPlaying
                              ? "Playing on court"
                              : p.checkedIn
                                  ? "Ready to play"
                                  : "Not checked in";

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.state.setSelectedPlayerId(p.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    // Avatar circle with initials
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: p.checkedIn
                                            ? AppColors.darkGreenGradient
                                            : null,
                                        color: p.checkedIn
                                            ? null
                                            : AppColors.surfaceSecondary,
                                        shape: BoxShape.circle,
                                        boxShadow: p.checkedIn
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.darkGreen.withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          p.name.isNotEmpty ? p.name[0].toUpperCase() : "P",
                                          style: TextStyle(
                                            color: p.checkedIn ? Colors.white : AppColors.textSecondary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Name & Subtitle
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
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "$statusText · ${p.played} matches",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                                                  color: isPlaying ? AppColors.gold : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Check-in toggle Button
                                    GestureDetector(
                                      onTap: isPlaying ? null : () => widget.state.toggleCheckIn(p.id),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: p.checkedIn ? AppColors.darkGreenGradient : null,
                                          color: p.checkedIn ? null : Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: p.checkedIn ? Colors.transparent : AppColors.border,
                                            width: 1.5,
                                          ),
                                          boxShadow: p.checkedIn
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.emerald.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              p.checkedIn ? Icons.check_rounded : Icons.add_rounded,
                                              size: 16,
                                              color: p.checkedIn ? Colors.white : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              p.checkedIn ? "Checked in" : "Check in",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: p.checkedIn ? Colors.white : AppColors.textSecondary,
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
                        },
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
