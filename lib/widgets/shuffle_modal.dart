import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShuffleModal extends StatefulWidget {
  final int eligibleCount;
  final int freeCourts;
  final String error;
  final Function(int numMatches) onPick;
  final VoidCallback onClose;

  const ShuffleModal({
    super.key,
    required this.eligibleCount,
    required this.freeCourts,
    required this.error,
    required this.onPick,
    required this.onClose,
  });

  @override
  State<ShuffleModal> createState() => _ShuffleModalState();
}

class _ShuffleModalState extends State<ShuffleModal> {
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    const options = [1, 2, 3, 4];
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 500 : double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isDesktop ? 24 : 0),
          bottomRight: Radius.circular(isDesktop ? 24 : 0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Shuffle Match",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.eligibleCount} players ready · ${widget.freeCourts} court${widget.freeCourts == 1 ? '' : 's'} available",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isCloseHovered ? AppColors.surfaceTertiary : AppColors.surfaceSecondary,
                        shape: BoxShape.circle,
                        boxShadow: _isCloseHovered
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Select number of matches:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Options Grid (1, 2, 3, 4)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final n = options[index];
                final disabled = widget.eligibleCount < n * 4 || widget.freeCourts < n;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled ? null : () => widget.onPick(n),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: disabled
                            ? AppColors.surfaceSecondary.withValues(alpha: 0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: disabled
                              ? AppColors.borderSubtle.withValues(alpha: 0.5)
                              : AppColors.emeraldLight.withValues(alpha: 0.5),
                          width: disabled ? 1.0 : 1.5,
                        ),
                        boxShadow: disabled
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$n Match${n > 1 ? 'es' : ''}",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: disabled ? AppColors.textMuted : AppColors.darkGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${n * 4} Players ($n Court${n > 1 ? 's' : ''})",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: disabled ? AppColors.textMuted.withValues(alpha: 0.7) : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (disabled) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.eligibleCount < n * 4
                                    ? AppColors.crimsonSoft
                                    : AppColors.amberBadgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.eligibleCount < n * 4
                                    ? "Needs ${n * 4} players (${widget.eligibleCount} ready)"
                                    : "Only ${widget.freeCourts} court${widget.freeCourts == 1 ? '' : 's'} available",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: widget.eligibleCount < n * 4
                                      ? AppColors.crimson
                                      : AppColors.amberBadge,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Hint note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "1 padel match = 4 players (2 vs 2). For 2 simultaneous courts, at least 8 ready players are required.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error Alert
            if (widget.error.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.crimsonSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.crimson.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.crimson, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.error,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
