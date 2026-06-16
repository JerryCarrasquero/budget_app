import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/feature/home/provider/home_provider.dart';

enum _CalendarFilterChoice { day, timeLength }

class HomePeriodCalendarButton extends StatelessWidget {
  final HomeProvider provider;

  const HomePeriodCalendarButton({super.key, required this.provider});

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  CalendarDatePicker2WithActionButtonsConfig _buildCalendarConfig({
    required BuildContext context,
    required CalendarDatePicker2Type type,
    required Set<DateTime> expenseDays,
  }) {
    final theme = Theme.of(context);
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: type,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      selectedDayHighlightColor: theme.colorScheme.primary,
      closeDialogOnCancelTapped: true,
      closeDialogOnOkTapped: true,
      dayBuilder:
          ({
            required date,
            textStyle,
            decoration,
            isSelected,
            isDisabled,
            isToday,
          }) {
            final hasExpense = expenseDays.contains(_normalizeDay(date));
            final markerColor = (isSelected ?? false)
                ? Colors.white
                : theme.colorScheme.primary;

            return Container(
              decoration: decoration,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      MaterialLocalizations.of(context).formatDecimal(date.day),
                      style: textStyle,
                    ),
                    if (hasExpense)
                      Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Future<void> _showCalendarActionSheet(BuildContext context) async {
    final text = context.text;
    final choice = await showModalBottomSheet<_CalendarFilterChoice>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(text.pickFilterTypeTitle)),
              ListTile(
                leading: const Icon(Icons.today),
                title: Text(text.filterByDay),
                onTap: () {
                  Navigator.of(sheetContext).pop(_CalendarFilterChoice.day);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(text.filterByTimeLength),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(_CalendarFilterChoice.timeLength);
                },
              ),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) {
      return;
    }

    if (choice == _CalendarFilterChoice.day) {
      await _pickDay(context);
      return;
    }

    await _pickDateRange(context);
  }

  Future<void> _pickDay(BuildContext context) async {
    final expenseDays = provider.expenseDaysForCalendar;
    final pickedValues = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(360, 420),
      config: _buildCalendarConfig(
        context: context,
        type: CalendarDatePicker2Type.single,
        expenseDays: expenseDays,
      ),
      value: [provider.periodStart],
    );

    if (pickedValues == null ||
        pickedValues.isEmpty ||
        pickedValues.first == null) {
      return;
    }

    provider.setDayPeriod(_normalizeDay(pickedValues.first!));
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final expenseDays = provider.expenseDaysForCalendar;
    final pickedValues = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(360, 420),
      config: _buildCalendarConfig(
        context: context,
        type: CalendarDatePicker2Type.range,
        expenseDays: expenseDays,
      ),
      value: [
        provider.periodStart,
        provider.periodEnd.subtract(const Duration(days: 1)),
      ],
    );

    if (pickedValues == null) {
      return;
    }

    final dates = pickedValues.whereType<DateTime>().toList();
    if (dates.length < 2) {
      return;
    }

    dates.sort();
    final start = _normalizeDay(dates.first);
    final end = _normalizeDay(dates.last).add(const Duration(days: 1));

    provider.setDateRangePeriod(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.calendar_today),
      onPressed: () async {
        await _showCalendarActionSheet(context);
      },
    );
  }
}
