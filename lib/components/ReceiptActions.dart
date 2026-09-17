import 'package:flutter/material.dart';
import '../utils/Extensions/app_common.dart' show toast;

import '../utils/Colors.dart';
import '../utils/ReceiptService.dart';

/// Share + Download buttons for a payment receipt. Each button shows its own spinner.
class ReceiptActions extends StatefulWidget {
  final ReceiptData data;
  /// icon-only buttons for list rows
  final bool compact;

  const ReceiptActions({super.key, required this.data, this.compact = false});

  @override
  State<ReceiptActions> createState() => _ReceiptActionsState();
}

class _ReceiptActionsState extends State<ReceiptActions> {
  bool sharing = false;
  bool downloading = false;

  Future<void> _share() async {
    if (sharing || downloading) return;
    setState(() => sharing = true);
    try {
      await ReceiptService.share(widget.data);
    } catch (e) {
      toast('Could not share the receipt');
    }
    if (mounted) setState(() => sharing = false);
  }

  Future<void> _download() async {
    if (sharing || downloading) return;
    setState(() => downloading = true);
    try {
      final path = await ReceiptService.download(widget.data);
      toast(path.contains('/Download') ? 'Receipt saved to Downloads' : 'Receipt saved');
    } catch (e) {
      toast('Could not save the receipt');
    }
    if (mounted) setState(() => downloading = false);
  }

  Widget _button({required IconData icon, required String label, required bool busy, required VoidCallback onTap}) {
    return Expanded(
      child: SizedBox(
        height: 46,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandBlue,
            side: BorderSide(color: brandBlue.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: (sharing || downloading) ? null : onTap,
          icon: busy ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: brandBlue)) : Icon(icon, size: 19),
          label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required String tooltip, required bool busy, required VoidCallback onTap}) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: (sharing || downloading) ? null : onTap,
      icon: busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: brandBlue)) : Icon(icon, size: 20, color: brandBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _iconButton(icon: Icons.share_rounded, tooltip: 'Share receipt', busy: sharing, onTap: _share),
        _iconButton(icon: Icons.download_rounded, tooltip: 'Download receipt', busy: downloading, onTap: _download),
      ]);
    }
    return Row(
      children: [
        _button(icon: Icons.share_rounded, label: 'Share', busy: sharing, onTap: _share),
        SizedBox(width: 12),
        _button(icon: Icons.download_rounded, label: 'Download', busy: downloading, onTap: _download),
      ],
    );
  }
}
