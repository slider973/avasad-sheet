import 'package:flutter/material.dart';

class TimesheetCalendarHeader extends StatelessWidget {
  final String title;

  const TimesheetCalendarHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
    );
  }
}