import 'package:flutter/material.dart';

import 'package:duitku/core/constants/app_defaults.dart';

/// Icons are persisted as code points, but Flutter can only tree-shake icon
/// fonts when every [IconData] is a compile-time constant. Stored code points
/// are therefore resolved back to the constant icons the app ships with.
class AppIcons {
  const AppIcons._();

  static const List<IconData> library = [
    ...AppDefaults.iconChoices,
    Icons.payments_outlined,
    Icons.card_giftcard,
    Icons.redeem,
    Icons.account_balance_outlined,
    Icons.attach_money,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.child_care,
    Icons.build,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.local_gas_station,
    Icons.beach_access,
    Icons.volunteer_activism,
  ];

  static final Map<int, IconData> _byCodePoint = {
    for (final icon in library) icon.codePoint: icon,
  };

  static IconData resolve(int codePoint) =>
      _byCodePoint[codePoint] ?? Icons.more_horiz;
}
