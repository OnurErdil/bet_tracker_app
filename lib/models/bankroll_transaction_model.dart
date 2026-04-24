import 'package:cloud_firestore/cloud_firestore.dart';

class BankrollTransaction {
  final String? id;
  final String userId;
  final double amount;
  final String type; // deposit / withdraw
  final String note;
  final DateTime createdAt;

  BankrollTransaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
    }

    return 0.0;
  }

  static String _readType(dynamic value) {
    final normalized = (value ?? '').toString().trim();

    if (normalized == 'deposit' || normalized == 'withdraw') {
      return normalized;
    }

    return 'deposit';
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value.trim()) ?? DateTime.now();
    }

    return DateTime.now();
  }

  factory BankrollTransaction.fromMap(Map<String, dynamic> map, String id) {
    return BankrollTransaction(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      amount: _readDouble(map['amount']),
      type: _readType(map['type']),
      note: (map['note'] ?? '').toString(),
      createdAt: _readDateTime(map['createdAt']),
    );
  }
}