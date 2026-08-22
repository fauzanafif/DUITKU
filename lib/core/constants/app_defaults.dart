import 'package:flutter/material.dart';

import 'package:duitku/data/models/account.dart';
import 'package:duitku/data/models/category.dart';

class DefaultCategorySeed {
  const DefaultCategorySeed(this.name, this.kind, this.icon, this.color);

  final String name;
  final CategoryKind kind;
  final IconData icon;
  final Color color;
}

class AppDefaults {
  const AppDefaults._();

  static const String cashAccountName = 'Cash';

  static const List<DefaultCategorySeed> categories = [
    DefaultCategorySeed(
        'Gaji', CategoryKind.income, Icons.payments_outlined, Color(0xFF16A34A)),
    DefaultCategorySeed('Bonus', CategoryKind.income, Icons.card_giftcard,
        Color(0xFF0891B2)),
    DefaultCategorySeed(
        'Freelance', CategoryKind.income, Icons.laptop_mac, Color(0xFF7C3AED)),
    DefaultCategorySeed('Investasi', CategoryKind.income, Icons.trending_up,
        Color(0xFF2563EB)),
    DefaultCategorySeed('Hadiah', CategoryKind.income, Icons.redeem,
        Color(0xFFDB2777)),
    DefaultCategorySeed('Lainnya', CategoryKind.income, Icons.more_horiz,
        Color(0xFF64748B)),
    DefaultCategorySeed('Makanan', CategoryKind.expense, Icons.restaurant,
        Color(0xFFEA580C)),
    DefaultCategorySeed('Transportasi', CategoryKind.expense,
        Icons.directions_bus, Color(0xFF2563EB)),
    DefaultCategorySeed('Belanja', CategoryKind.expense, Icons.shopping_bag,
        Color(0xFFDB2777)),
    DefaultCategorySeed('Tagihan', CategoryKind.expense, Icons.receipt_long,
        Color(0xFF9333EA)),
    DefaultCategorySeed('Hiburan', CategoryKind.expense, Icons.movie,
        Color(0xFF0891B2)),
    DefaultCategorySeed('Kesehatan', CategoryKind.expense,
        Icons.medical_services, Color(0xFF16A34A)),
    DefaultCategorySeed('Pendidikan', CategoryKind.expense, Icons.school,
        Color(0xFF4F46E5)),
    DefaultCategorySeed(
        'Internet', CategoryKind.expense, Icons.wifi, Color(0xFF0EA5E9)),
    DefaultCategorySeed('Pulsa', CategoryKind.expense, Icons.smartphone,
        Color(0xFF14B8A6)),
    DefaultCategorySeed('Kebutuhan Rumah', CategoryKind.expense, Icons.home,
        Color(0xFFF59E0B)),
    DefaultCategorySeed('Lainnya', CategoryKind.expense, Icons.more_horiz,
        Color(0xFF64748B)),
  ];

  static const Map<AccountType, IconData> accountTypeIcons = {
    AccountType.bank: Icons.account_balance,
    AccountType.cash: Icons.payments,
    AccountType.ewallet: Icons.account_balance_wallet,
    AccountType.other: Icons.savings,
    AccountType.allowance: Icons.child_care,
  };

  static const List<Color> palette = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF9333EA),
    Color(0xFF0891B2),
    Color(0xFFF59E0B),
    Color(0xFF64748B),
  ];

  static const List<IconData> iconChoices = [
    Icons.account_balance,
    Icons.payments,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.credit_card,
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.directions_bus,
    Icons.receipt_long,
    Icons.medical_services,
    Icons.school,
    Icons.wifi,
    Icons.smartphone,
    Icons.home,
    Icons.movie,
    Icons.laptop_mac,
    Icons.trending_up,
    Icons.flight_takeoff,
    Icons.pets,
    Icons.more_horiz,
  ];
}
