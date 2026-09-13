import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ShareSessionModal extends StatefulWidget {
  final PadelSession session;
  final VoidCallback onClose;

  const ShareSessionModal({
    super.key,
    required this.session,
    required this.onClose,
  });

  @override
  State<ShareSessionModal> createState() => _ShareSessionModalState();
}

class _ShareSessionModalState extends State<ShareSessionModal> {
  bool _copiedCode = false;
  bool _copiedLink = false;
  bool _copiedText = false;

  String get _shareUrl {
    final base = Uri.base.toString().split('?').first;
    final cleanBase = (base.isEmpty || base.startsWith('file://'))
        ? 'https://padel-shuffle.vercel.app/'
        : base;
    return '$cleanBase?code=${widget.session.passcode}';
  }

  String get _invitationMessage {
    final name = widget.session.name.isNotEmpty ? widget.session.name : 'Padel Tournament';
    final date = widget.session.date.isNotEmpty ? widget.session.date : 'Hari ini';
    final time = widget.session.timeStart.isNotEmpty
        ? ' (${widget.session.timeStart}–${widget.session.timeEnd})'
        : '';

    return '''🎾 *Turnamen Padel: $name*
📅 Tanggal: $date$time
🔑 *Kode Sesi: ${widget.session.passcode}*

Yuk gabung & pantau live score, jadwal match, dan ranking pemain di sini:
$_shareUrl''';
  }

  void _copy(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (type == 'code') _copiedCode = true;
      if (type == 'link') _copiedLink = true;
      if (type == 'text') _copiedText = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              type == 'code'
                  ? 'Kode sesi berhasil disalin!'
                  : type == 'link'
                      ? 'Link sesi berhasil disalin!'
                      : 'Undangan turnamen berhasil disalin!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (type == 'code') _copiedCode = false;
          if (type == 'link') _copiedLink = false;
          if (type == 'text') _copiedText = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle (Mobile) & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Share Session",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "Bagikan kode agar pemain bisa join",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tournament Info Summary Pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_tennis_rounded, color: AppColors.emerald, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.name.isEmpty ? "Padel Session" : widget.session.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${widget.session.date.isEmpty ? 'Hari ini' : widget.session.date}${widget.session.timeStart.isNotEmpty ? ' · ${widget.session.timeStart}–${widget.session.timeEnd}' : ''} · ${widget.session.courtsTotal} Courts",
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Big Session Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C382B), Color(0xFF144D3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "UNIQUE SESSION CODE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.mintAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.session.passcode,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _copy(widget.session.passcode, 'code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copiedCode ? AppColors.mintAccent : Colors.white,
                      foregroundColor: AppColors.darkGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _copiedCode ? Icons.check_rounded : Icons.copy_rounded,
                      size: 16,
                      color: AppColors.darkGreen,
                    ),
                    label: Text(
                      _copiedCode ? "Copied!" : "Copy Code",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(_shareUrl, 'link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _copiedLink ? AppColors.emerald.withValues(alpha: 0.1) : Colors.white,
                    ),
                    icon: Icon(
                      _copiedLink ? Icons.check_rounded : Icons.link_rounded,
                      size: 17,
                      color: AppColors.darkGreen,
                    ),
                    label: Text(
                      _copiedLink ? "Link Copied!" : "Copy Link",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _copy(_invitationMessage, 'text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copiedText ? AppColors.emerald : AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _copiedText ? Icons.check_rounded : Icons.chat_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _copiedText ? "Tersalin!" : "Copy WhatsApp",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informational tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.emerald),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Pemain atau penonton cukup membuka aplikasi dan memasukkan Kode Sesi di atas untuk langsung melihat Live Courts & Leaderboard.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
