import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkTimeTracker extends StatefulWidget {
  @override
  _WorkTimeTrackerState createState() => _WorkTimeTrackerState();
}

class _WorkTimeTrackerState extends State<WorkTimeTracker> {
  DateTime? _lastClockIn;
  List<String> _timeLog = [];

  void _clockAction(String action) {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    setState(() {
      _timeLog.add('$action at $formattedTime');
      if (action == 'Entrée') {
        _lastClockIn = now;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLastClockIn(),
        SizedBox(height: 20),
        _buildActionButtons(),
        SizedBox(height: 20),
        _buildTimeLog(),
      ],
    );
  }

  Widget _buildLastClockIn() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Started',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _lastClockIn != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(_lastClockIn!)
                : 'Pas encore pointé',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildActionButton('Entrée', Colors.green),
        _buildActionButton('Début pause', Colors.orange),
        _buildActionButton('Fin pause', Colors.blue),
        _buildActionButton('Sortie', Colors.red),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _clockAction(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildTimeLog() {
    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: _timeLog.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_timeLog[_timeLog.length - 1 - index]),
          );
        },
      ),
    );
  }
}