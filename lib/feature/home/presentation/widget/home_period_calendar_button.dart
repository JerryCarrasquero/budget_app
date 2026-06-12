import 'package:flutter/material.dart';
import 'package:budget_app/core/text/app_text_provider.dart';
import 'package:budget_app/feature/home/provider/home_provider.dart';

enum _CalendarFilterChoice { day, timeLength }

class HomePeriodCalendarButton extends StatelessWidget {
  final HomeProvider provider;

  const HomePeriodCalendarButton({
    super.key,
    required this.provider,
  });

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  Future<void> _showCalendarActionSheet(BuildContext context) async {
    final text = context.text;
    final choice = await showModalBottomSheet<_CalendarFilterChoice>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(text.pickFilterTypeTitle),
              ),
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
                  Navigator.of(sheetContext).pop(_CalendarFilterChoice.timeLength);
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
    final text = context.text;
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.periodStart,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: text.selectDayTitle,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked == null) {
      return;
    }

    provider.setDayPeriod(picked);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: provider.periodStart,
        end: provider.periodEnd.subtract(const Duration(days: 1)),
      ),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: context.text.selectStartMonthTitle,
      saveText: context.text.save,
      cancelText: context.text.cancel,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedRange == null) {
      return;
    }

    provider.setDateRangePeriod(
      start: _monthStart(pickedRange.start),
      end: pickedRange.end.add(const Duration(days: 1)),
    );
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