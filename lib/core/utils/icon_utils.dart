import 'package:flutter/material.dart';

/// All Material icons the app may display from stored Hive code points.
/// Using only const [IconData] values keeps release icon tree-shaking happy.
const List<IconData> kRegisteredAppIcons = [
  Icons.restaurant_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.receipt_long_rounded,
  Icons.favorite_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.home_rounded,
  Icons.pets_rounded,
  Icons.sports_esports_rounded,
  Icons.more_horiz_rounded,
  Icons.payments_rounded,
  Icons.account_balance_rounded,
  Icons.account_balance_wallet_rounded,
  Icons.credit_card_rounded,
  Icons.work_rounded,
  Icons.category_rounded,
  Icons.category,
  Icons.water_drop_rounded,
];

final Map<int, IconData> _iconsByCodePoint = {
  for (final icon in kRegisteredAppIcons) icon.codePoint: icon,
};

/// Resolves a stored icon code point to a const [IconData].
IconData iconFromCode(int codePoint) {
  return _iconsByCodePoint[codePoint] ?? Icons.category_rounded;
}
