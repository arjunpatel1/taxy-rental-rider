import 'package:flutter/material.dart';
import '../utils/BrandTheme.dart';

/// A bounded balance header shared by wallet and top-up pages.
class WalletBalanceCard extends StatelessWidget {
  final String title;
  final Widget amount;
  final String addMoneyLabel;
  final VoidCallback? onAddMoney;
  const WalletBalanceCard({super.key, required this.title, required this.amount,
    this.addMoneyLabel = 'Add money', this.onAddMoney});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [BrandTokens.blue, Color(0xFF1760C8)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: amount)),
        ])),
      ]),
      if (onAddMoney != null) ...[
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onAddMoney, icon: const Icon(Icons.add_rounded),
          label: Text(addMoneyLabel),
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: BrandTokens.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
      ],
    ]),
  );
}
