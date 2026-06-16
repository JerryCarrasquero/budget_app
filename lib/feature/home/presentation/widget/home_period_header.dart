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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                periodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
