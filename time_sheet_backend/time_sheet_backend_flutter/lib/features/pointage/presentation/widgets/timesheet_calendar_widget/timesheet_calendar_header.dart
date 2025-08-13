import 'package:flutter/material.dart';

class TimesheetCalendarHeader extends StatelessWidget {
  final String title;

  const TimesheetCalendarHeader({Key? key, required this.title}) : super(key: key);

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