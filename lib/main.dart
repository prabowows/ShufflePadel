import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/models.dart';
import 'screens/add_players_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/home_tab.dart';
import 'screens/players_tab.dart';
import 'screens/ranking_tab.dart';
import 'screens/splash_screen.dart';
import 'services/firestore_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/profile_modal.dart';
import 'widgets/shuffle_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirestoreService().initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PadelShuffleApp());
}

class PadelShuffleApp extends StatelessWidget {
  const PadelShuffleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel Shuffle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: '-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif',
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        colorScheme: const ColorScheme.light(
          primary: AppColors.darkGreen,
          onPrimary: Colors.white,
          secondary: AppColors.darkGreen,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: const RootController(),
    );
  }
}

class RootController extends StatefulWidget {
  const RootController({super.key});

  @override
  State<RootController> createState() => _RootControllerState();
}

class _RootControllerState extends State<RootController> {
  final AppState state = AppState();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    state.removeListener(_onStateChanged);
    state.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _showShuffleModal() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: ShuffleModal(
              eligibleCount: state.eligiblePlayers.length,
              freeCourts: state.freeCourts,
              error: state.shuffleError,
              onPick: (n) {
                state.tryShuffle(n);
                if (state.shuffleError.isEmpty && mounted) {
                  Navigator.pop(context);
                }
              },
              onClose: () => Navigator.pop(context),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return ShuffleModal(
            eligibleCount: state.eligiblePlayers.length,
            freeCourts: state.freeCourts,
            error: state.shuffleError,
            onPick: (n) {
              state.tryShuffle(n);
              if (state.shuffleError.isEmpty && mounted) {
                Navigator.pop(context);
              }
            },
            onClose: () => Navigator.pop(context),
          );
        },
      );
    }
  }

  void _showProfileModal(Player player) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: ProfileModal(
              player: player,
              rank: state.selectedRank,
              onClose: () => Navigator.pop(context),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return ProfileModal(
            player: player,
            rank: state.selectedRank,
            onClose: () => Navigator.pop(context),
          );
        },
      );
    }
  }

  void _confirmExitSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Exit / Switch Session?",
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGreen),
        ),
        content: const Text(
          "This session is automatically saved. You can reopen it anytime using the date and passcode.",
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              state.exitSession();
            },
            child: const Text("Exit Session"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.shuffleOpen) {
        state.shuffleOpen = false;
        _showShuffleModal();
      }
      if (state.selectedPlayerId != null) {
        final p = state.selectedPlayer;
        state.selectedPlayerId = null;
        if (p != null) {
          _showProfileModal(p);
        }
      }
    });

    if (state.setupStep == "create") {
      return CreateTournamentScreen(state: state);
    } else if (state.setupStep == "roster") {
      return AddPlayersScreen(state: state);
    } else {
      return _buildMainAppView();
    }
  }

  Widget _buildMainAppView() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final busyCourts = state.courtsTotal - state.freeCourts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (state.firestoreBanner.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.crimsonSoft,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.crimson, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.firestoreBanner,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.crimson,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => state.clearFirestoreBanner(),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.crimson),
                    ),
                  ],
                ),
              ),
            // Clean White Top App Bar with Dark Green elements
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 20,
                vertical: isDesktop ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: App Logo & Session Information
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryButtonGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.emerald.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_tennis_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.session.name.isEmpty ? "Padel Session" : state.session.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                Text(
                                  "${state.session.date.isEmpty ? 'Padel Tournament' : state.session.date}${state.session.timeStart.isNotEmpty ? ' · ${state.session.timeStart}–${state.session.timeEnd}' : ''}",
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Center: Navigation Tabs (Clean White & Dark Green Pill)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                spreadRadius: -1,
                                offset: const Offset(0, 2),
                                blurStyle: BlurStyle.inner,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDesktopTabButton("home", Icons.dashboard_rounded, "Live Courts"),
                              _buildDesktopTabButton("ranking", Icons.emoji_events_rounded, "Ranking"),
                              _buildDesktopTabButton("players", Icons.people_alt_rounded, "Players"),
                            ],
                          ),
                        ),

                        // Right: Clean Status Badges
                        Row(
                          children: [
                            if (state.session.passcode.isNotEmpty) ...[
                              _buildHeaderStatusBadge(
                                icon: Icons.lock_outline_rounded,
                                label: "Passcode: ${state.session.passcode}",
                              ),
                              const SizedBox(width: 10),
                            ],
                            _buildHeaderStatusBadge(
                              icon: Icons.check_circle_outline_rounded,
                              label: "${state.checkedInCount} Checked in",
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatusBadge(
                              icon: Icons.grid_view_rounded,
                              label: "$busyCourts/${state.courtsTotal} Courts Busy",
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatusBadge(
                              icon: Icons.history_rounded,
                              label: "${state.matchCounter - 1} Matches",
                            ),
                            const SizedBox(width: 10),
                            // Exit / Switch Session Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _confirmExitSession(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.logout_rounded, size: 14, color: AppColors.textSecondary),
                                      SizedBox(width: 4),
                                      Text(
                                        "Switch Session",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Mobile Header Top Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryButtonGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.emerald.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.sports_tennis_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.session.name.isEmpty ? "Padel Session" : state.session.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        color: AppColors.darkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${state.session.date.isEmpty ? 'Padel Tournament' : state.session.date}${state.session.timeStart.isNotEmpty ? ' · ${state.session.timeStart}–${state.session.timeEnd}' : ''}",
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${state.matchCounter - 1}",
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkGreen,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "matches",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Mobile Status Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.darkGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${state.checkedInCount} in",
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.darkGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$busyCourts/${state.courtsTotal} busy",
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.session.passcode.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.emerald),
                                      const SizedBox(width: 3),
                                      Text(
                                        state.session.passcode,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.emerald,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            InkWell(
                              onTap: () => _confirmExitSession(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout_rounded, size: 12, color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text(
                                      "Ganti",
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Main Tab Body
            Expanded(
              child: _buildCurrentTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
    );
  }

  Widget _buildDesktopTabButton(String tabKey, IconData icon, String label) {
    final isActive = state.activeTab == tabKey;
    return GestureDetector(
      onTap: () => state.setActiveTab(tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryButtonGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatusBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.emerald),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (state.activeTab) {
      case "home":
        return HomeTab(
          state: state,
          onGoToPlayers: () => state.setActiveTab("players"),
        );
      case "ranking":
        return RankingTab(state: state);
      case "players":
        return PlayersTab(state: state);
      default:
        return HomeTab(
          state: state,
          onGoToPlayers: () => state.setActiveTab("players"),
        );
    }
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _buildMobileNavItem("home", Icons.dashboard_rounded, "Home"),
              _buildMobileNavItem("ranking", Icons.emoji_events_rounded, "Ranking"),
              _buildMobileNavItem("players", Icons.people_rounded, "Players"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(String tabKey, IconData icon, String label) {
    final isActive = state.activeTab == tabKey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => state.setActiveTab(tabKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? AppColors.darkGreen : AppColors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? AppColors.darkGreen : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: isActive ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
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
