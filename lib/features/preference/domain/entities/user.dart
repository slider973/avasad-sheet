

import 'dart:typed_data';

class User {
  final String firstName;
  final String lastName;
  final String company;
  final Uint8List? signature;
  final bool isDeliveryManager;
  final double normalHoursThreshold;

  User({
    required this.firstName,
    required this.lastName,
    required this.company,
    this.signature,
    required this.isDeliveryManager,
    this.normalHoursThreshold = 8.0,
  });

  String get fullName => '$firstName $lastName';
}