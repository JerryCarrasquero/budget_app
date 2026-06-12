import 'package:flutter/material.dart';

class HomePeriodHeader extends StatelessWidget {
  final String periodTitle;
  final String periodLabel;
  final Widget trailing;

  const HomePeriodHeader({
    super.key,
    required this.periodTitle,
    required this.periodLabel,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(periodTitle, style: Theme.of(context).textTheme.bodySmall),
            Text(
              periodLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        trailing,
      ],
    );
  }
}