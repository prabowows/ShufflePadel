import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_time_picker.dart';

class CreateTournamentScreen extends StatefulWidget {
  final AppState state;

  const CreateTournamentScreen({
    super.key,
    required this.state,
  });

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  // Mode: "create" or "join"
  String _mode = "create";

  // Create form controllers
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _passcodeController;

  // Join form controllers
  late TextEditingController _joinDateController;
  late TextEditingController _joinPasscodeController;

  List<Map<String, dynamic>> _savedSessions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.session.name);
    _dateController = TextEditingController(text: widget.state.session.date);
    _startController = TextEditingController(text: widget.state.session.timeStart);
    _endController = TextEditingController(text: widget.state.session.timeEnd);
    _passcodeController = TextEditingController(text: widget.state.session.passcode);

    _joinDateController = TextEditingController();
    _joinPasscodeController = TextEditingController();

    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = await widget.state.loadSavedSessions();
    if (mounted) {
      setState(() {
        _savedSessions = list;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _passcodeController.dispose();
    _joinDateController.dispose();
    _joinPasscodeController.dispose();
    super.dispose();
  }

  void _syncState() {
    widget.state.session.name = _nameController.text;
    widget.state.session.date = _dateController.text;
    widget.state.session.timeStart = _startController.text;
    widget.state.session.timeEnd = _endController.text;
    widget.state.session.passcode = _passcodeController.text.trim();
  }

  Future<void> _pickDate({bool isJoin = false}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        if (isJoin) {
          _joinDateController.text = formatted;
        } else {
          _dateController.text = formatted;
          _syncState();
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final controller = isStart ? _startController : _endController;
    TimeOfDay initial = const TimeOfDay(hour: 14, minute: 0);

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    final picked = await showModernTimePicker(
      context: context,
      initialTime: initial,
      title: isStart ? "Select Start Time" : "Select End Time",
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formatted;
        _syncState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _nameController.text.trim().isNotEmpty && _passcodeController.text.trim().isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: screenWidth >= 950
          ? _buildDesktopLayout(canContinue, screenWidth)
          : _buildMobileLayout(canContinue),
    );
  }

  // ─────────────────────────────────────────────
  //  DESKTOP: Split-screen hero + form
  // ─────────────────────────────────────────────
  Widget _buildDesktopLayout(bool canContinue, double screenWidth) {
    return Row(
      children: [
        // Left: Hero visual panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF092A20), Color(0xFF0C382B), Color(0xFF144D3D)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo area
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_tennis_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Padel Shuffle",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Hero image
                    Expanded(
                      flex: 8,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/padel_hero.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Tagline
                    const Text(
                      "Organize padel tournaments\neasily and quickly.",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Smart auto-shuffle, real-time leaderboard, and secure passcode access.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Feature pills
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildFeaturePill(Icons.shuffle_rounded, "Smart Shuffle"),
                        _buildFeaturePill(Icons.emoji_events_rounded, "Live Ranking"),
                        _buildFeaturePill(Icons.lock_rounded, "Session Passcode"),
                        _buildFeaturePill(Icons.grid_view_rounded, "Multi-Court"),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right: Form panel (Create or Join)
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeSwitcher(),
                      const SizedBox(height: 28),
                      _mode == "create"
                          ? _buildCreateFormContent(canContinue)
                          : _buildJoinFormContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  MOBILE: Stacked hero + form
  // ─────────────────────────────────────────────
  Widget _buildMobileLayout(bool canContinue) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF092A20), Color(0xFF0C382B), Color(0xFF144D3D)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo row
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sports_tennis_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Padel Shuffle",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Hero image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/padel_hero.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tagline
                    const Text(
                      "Organize padel tournaments\neasily and quickly.",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Smart auto-shuffle, real-time leaderboard, & secure passcode.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form section
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSwitcher(),
                const SizedBox(height: 24),
                _mode == "create"
                    ? _buildCreateFormContent(canContinue)
                    : _buildJoinFormContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MODE SWITCHER: Create Session vs Join Session
  // ─────────────────────────────────────────────
  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = "create";
                  widget.state.joinError = "";
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == "create" ? AppColors.darkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == "create"
                      ? [
                          BoxShadow(
                            color: AppColors.darkGreen.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: _mode == "create" ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Create Session",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _mode == "create" ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = "join";
                  widget.state.joinError = "";
                });
                _loadSaved();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == "join" ? AppColors.darkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == "join"
                      ? [
                          BoxShadow(
                            color: AppColors.darkGreen.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 16,
                      color: _mode == "join" ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Join / View Session",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _mode == "join" ? Colors.white : AppColors.textSecondary,
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
  }

  // ─────────────────────────────────────────────
  //  CREATE FORM CONTENT
  // ─────────────────────────────────────────────
  Widget _buildCreateFormContent(bool canContinue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "STEP 1 OF 2",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.darkGreen,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        const Text(
          "Create Tournament",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Set up tournament details & set a passcode so players can join to view scores.",
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 26),

        // Tournament Name
        _buildLabel("Tournament Name"),
        const SizedBox(height: 8),
        _buildModernTextField(
          controller: _nameController,
          hint: "e.g. Saturday Padel League",
          icon: Icons.sports_tennis_rounded,
          onChanged: (val) {
            _syncState();
            setState(() {});
          },
        ),
        const SizedBox(height: 18),

        // Session Passcode
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildLabel("Session Passcode"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Required for access",
                style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildModernTextField(
          controller: _passcodeController,
          hint: "e.g. 1234 or PADEL26",
          icon: Icons.lock_outline_rounded,
          onChanged: (val) {
            _syncState();
            setState(() {});
          },
        ),
        const SizedBox(height: 6),
        const Text(
          "💡 This passcode is used by players/spectators to join and view tournament results.",
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Date
        _buildLabel("Session Date"),
        const SizedBox(height: 8),
        _buildPickerField(
          value: _dateController.text,
          hint: "Select session date",
          icon: Icons.calendar_today_rounded,
          onTap: () => _pickDate(isJoin: false),
        ),
        const SizedBox(height: 18),

        // Time
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Start"),
                  const SizedBox(height: 8),
                  _buildPickerField(
                    value: _startController.text,
                    hint: "Select time",
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("End"),
                  const SizedBox(height: 8),
                  _buildPickerField(
                    value: _endController.text,
                    hint: "Select time",
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Court selector
        _buildLabel("Number of Courts"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppDecorations.cleanWhiteCard(borderRadius: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.darkGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.state.session.courtsTotal} Active Court${widget.state.session.courtsTotal > 1 ? 's' : ''}",
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            "Up to ${widget.state.session.courtsTotal * 4} players playing",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _buildStepperButton(
                    icon: Icons.remove_rounded,
                    enabled: widget.state.session.courtsTotal > 1,
                    onTap: () {
                      if (widget.state.session.courtsTotal > 1) {
                        setState(() {
                          widget.state.session.courtsTotal--;
                        });
                      }
                    },
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    alignment: Alignment.center,
                    child: Text(
                      "${widget.state.session.courtsTotal}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                  _buildStepperButton(
                    icon: Icons.add_rounded,
                    enabled: widget.state.session.courtsTotal < 4,
                    onTap: () {
                      if (widget.state.session.courtsTotal < 4) {
                        setState(() {
                          widget.state.session.courtsTotal++;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Continue button with gradient
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: canContinue ? AppColors.primaryButtonGradient : null,
              color: canContinue ? null : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: canContinue
                  ? [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: canContinue
                  ? () {
                      _syncState();
                      widget.state.startTournament();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Continue: Add Players",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  JOIN / VIEW FORM CONTENT
  // ─────────────────────────────────────────────
  Widget _buildJoinFormContent() {
    final canJoin = _joinDateController.text.trim().isNotEmpty && _joinPasscodeController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "SESSION ACCESS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.darkGreen,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        const Text(
          "Join / View Session Results",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Enter tournament date & passcode to view live court scores or the final leaderboard.",
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Session Date
        _buildLabel("Session Date"),
        const SizedBox(height: 8),
        _buildPickerField(
          value: _joinDateController.text,
          hint: "Select session date to view",
          icon: Icons.calendar_today_rounded,
          onTap: () => _pickDate(isJoin: true),
        ),
        const SizedBox(height: 18),

        // Passcode
        _buildLabel("Session Passcode"),
        const SizedBox(height: 8),
        _buildModernTextField(
          controller: _joinPasscodeController,
          hint: "Enter session passcode",
          icon: Icons.lock_outline_rounded,
          onChanged: (val) => setState(() {}),
        ),

        // Error message if any
        if (widget.state.joinError.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.crimsonSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.crimson, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.state.joinError,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: canJoin ? AppColors.primaryButtonGradient : null,
              color: canJoin ? null : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: canJoin
                  ? [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: canJoin && !widget.state.isJoining
                  ? () async {
                      await widget.state.joinSessionByDateAndPasscode(
                        _joinDateController.text,
                        _joinPasscodeController.text,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: widget.state.isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Enter & View Session",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.login_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ),

        // Saved Sessions list on this device
        if (_savedSessions.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Saved Sessions on This Device",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "${_savedSessions.length} session${_savedSessions.length == 1 ? '' : 's'}",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedSessions.take(4).length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _savedSessions[index];
              final s = item['session'] as Map<String, dynamic>? ?? {};
              final name = s['name'] as String? ?? 'Padel Session';
              final date = s['date'] as String? ?? '';
              final passcode = s['passcode'] as String? ?? '';
              final pCount = (item['players'] as List<dynamic>?)?.length ?? 0;
              final mCount = (item['matches'] as List<dynamic>?)?.length ?? 0;

              return InkWell(
                onTap: () {
                  setState(() {
                    _joinDateController.text = date;
                    _joinPasscodeController.text = passcode;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.darkGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports_tennis_rounded, size: 16, color: AppColors.darkGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$date · $pCount player${pCount == 1 ? '' : 's'} · $mCount match${mCount == 1 ? '' : 'es'}",
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          "Select",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildPickerField({
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.darkGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : hint,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: AppColors.darkGreen)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: enabled ? AppColors.darkGreen.withValues(alpha: 0.08) : AppColors.surfaceTertiary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? AppColors.darkGreen.withValues(alpha: 0.2) : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.darkGreen : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
