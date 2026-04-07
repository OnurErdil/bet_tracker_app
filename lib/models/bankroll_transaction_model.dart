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

  factory BankrollTransaction.fromMap(Map<String, dynamic> map, String id) {
    return BankrollTransaction(
      id: id,
      userId: map['userId'],
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'],
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}