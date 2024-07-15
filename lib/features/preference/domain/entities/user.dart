

import 'dart:typed_data';

class User {
  final String firstName;
  final String lastName;
  final String company;
  final Uint8List? signature;

  User({
    required this.firstName,
    required this.lastName,
    required this.company,
    this.signature,
  });

  String get fullName => '$firstName $lastName';
}