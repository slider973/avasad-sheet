import 'dart:async';

import 'package:flutter/material.dart';

class WatchCounter extends StatefulWidget {

  const WatchCounter({super.key});

  @override
  State<WatchCounter> createState() => _WatchCounterState();
}

class _WatchCounterState extends State<WatchCounter> {
  DateTime selectedDate = DateTime.now();
  late String _timeString;
  Timer? _timer;
  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }
  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2,'0')}:${dateTime.minute.toString().padLeft(2,'0')}:${dateTime.second.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Text(_timeString);
  }
}
