import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankrollTransaction.fromMap', () {
    test('string tutar, geçerli type ve timestamp tarih okur', () {
      final date = DateTime(2026, 4, 26, 12, 30);

      final tx = BankrollTransaction.fromMap(
        {
          'userId': 'user-1',
          'amount': '1250,75',
          'type': 'withdraw',
          'note': 'para çekildi',
          'createdAt': Timestamp.fromDate(date),
        },
        'tx-1',
      );

      expect(tx.id, 'tx-1');
      expect(tx.userId, 'user-1');
      expect(tx.amount, 1250.75);
      expect(tx.type, 'withdraw');
      expect(tx.note, 'para çekildi');
      expect(tx.createdAt, date);
    });

    test('geçersiz amount ve type için güvenli varsayılan kullanır', () {
      final tx = BankrollTransaction.fromMap(
        {
          'userId': 'user-1',
          'amount': 'abc',
          'type': 'yanlis',
          'note': null,
          'createdAt': 0,
        },
        'tx-2',
      );

      expect(tx.amount, 0.0);
      expect(tx.type, 'deposit');
      expect(tx.note, '');
      expect(tx.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('BankrollTransaction.toMap', () {
    test('model alanlarını Firestore map formatına çevirir', () {
      final date = DateTime(2026, 4, 26, 14);

      final tx = BankrollTransaction(
        userId: 'user-1',
        amount: 500,
        type: 'deposit',
        note: 'ekleme',
        createdAt: date,
      );

      final map = tx.toMap();

      expect(map['userId'], 'user-1');
      expect(map['amount'], 500.0);
      expect(map['type'], 'deposit');
      expect(map['note'], 'ekleme');
      expect((map['createdAt'] as Timestamp).toDate(), date);
    });
  });
}