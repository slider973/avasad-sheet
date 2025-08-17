import 'package:flutter/material.dart';

class TimesheetCalendarHeader extends StatelessWidget {
  final String title;

  const TimesheetCalendarHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Text(title),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}
