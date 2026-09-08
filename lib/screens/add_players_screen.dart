import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddPlayersScreen extends StatefulWidget {
  final AppState state;

  const AddPlayersScreen({
    super.key,
    required this.state,
  });

  @override
  State<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends State<AddPlayersScreen> {
  final TextEditingController _rosterController = TextEditingController();

  void _handleAdd() {
    final text = _rosterController.text.trim();
    if (text.isNotEmpty) {
      widget.state.addRosterPlayer(text);
      _rosterController.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _rosterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minNeeded = 4;
    final canStart = widget.state.rosterPlayers.length >= minNeeded;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 20,
            vertical: isDesktop ? 48 : 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            decoration: isDesktop ? AppDecorations.cleanWhiteCard(borderRadius: 24) : null,
            padding: EdgeInsets.all(isDesktop ? 40 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.state.backToCreate(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.darkGreen),
                          SizedBox(width: 6),
                          Text(
                            "Edit tournament",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Step Indicator Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.darkGreenGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    "STEP 2 OF 2",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                const Text(
                  "Add Players",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${widget.state.session.name}${widget.state.session.date.isNotEmpty ? ' · ${widget.state.session.date}' : ''}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.state.firestoreBanner.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.crimson, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.state.firestoreBanner,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.crimson, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Add Player Input Row
                Container(
                  decoration: AppDecorations.cleanWhiteCard(borderRadius: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rosterController,
                          onSubmitted: (_) => _handleAdd(),
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Enter player name...",
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            prefixIcon: Icon(Icons.person_add_outlined, color: AppColors.darkGreen, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.darkGreenGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, size: 20),
                              SizedBox(width: 6),
                              Text("Add", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Roster Count Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${widget.state.rosterPlayers.length} Players Added",
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!canStart)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amberBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Minimum $minNeeded players (${minNeeded - widget.state.rosterPlayers.length} more needed)",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.amberBadge,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Roster List Container
                Container(
                  constraints: const BoxConstraints(minHeight: 200, maxHeight: 360),
                  decoration: AppDecorations.cleanWhiteCard(
                    borderRadius: 16,
                  ),
                  child: widget.state.rosterPlayers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.groups_rounded, size: 48, color: AppColors.textMuted),
                                SizedBox(height: 16),
                                Text(
                                  "No players added yet.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Type a player name above and press Add.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: widget.state.rosterPlayers.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.borderSubtle,
                          ),
                          itemBuilder: (context, index) {
                            final p = widget.state.rosterPlayers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    color: AppColors.textMuted,
                                    hoverColor: AppColors.crimsonSoft,
                                    highlightColor: AppColors.crimsonSoft,
                                    onPressed: () => widget.state.removeRosterPlayer(p.id),
                                    tooltip: "Remove player",
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    style: IconButton.styleFrom(
                                      foregroundColor: AppColors.crimson,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 36),

                // Start Session Button (Dark Green)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: canStart ? AppColors.darkGreenGradient : null,
                    color: canStart ? null : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canStart
                        ? [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: canStart ? () => widget.state.beginSession() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Padel Session",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.sports_tennis_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
