import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BankrollPage extends StatelessWidget {
  const BankrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Hareketleri'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BankrollTransaction>>(
        stream: BankrollService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Kasa hareketleri yüklenirken hata oluştu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(
              child: Text('Henüz işlem yok'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final tx = list[i];

              return Card(
                color: const Color(0xFF161A23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _showEditDialog(context, tx),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: (tx.type == 'deposit'
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444))
                        .withOpacity(0.15),
                    child: Icon(
                      tx.type == 'deposit'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: tx.type == 'deposit'
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  title: Text(
                    tx.note.trim().isEmpty ? 'İşlem' : tx.note,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${tx.type == 'deposit' ? 'Para Eklendi' : 'Para Çekildi'}\n${_formatDate(tx.createdAt)}',
                    ),
                  ),
                  trailing: Text(
                    '${tx.type == 'deposit' ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      color: tx.type == 'deposit'
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$minute';
  }

  static void _showAddDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'deposit';

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Yeni İşlem'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        hintText: 'Örn: 1000',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'İşlem Türü',
                        prefixIcon: Icon(Icons.swap_horiz),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'deposit',
                          child: Text('Para Ekle'),
                        ),
                        DropdownMenuItem(
                          value: 'withdraw',
                          child: Text('Para Çek'),
                        ),
                      ],
                      onChanged: (val) {
                        type = val ?? 'deposit';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Not',
                        hintText: 'Örn: Kasa takviyesi',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kullanıcı bulunamadı.'),
                        ),
                      );
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Geçerli bir tutar gir.'),
                        ),
                      );
                      return;
                    }

                    setState(() => isSaving = true);

                    final result = await BankrollService.addTransaction(
                      BankrollTransaction(
                        userId: user.uid,
                        amount: amount,
                        type: type,
                        note: noteController.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );

                    if (!context.mounted) return;

                    setState(() => isSaving = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İşlem eklendi.'),
                      ),
                    );
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void _showEditDialog(
      BuildContext context,
      BankrollTransaction tx,
      ) {
    final amountController = TextEditingController(
      text: tx.amount.toString(),
    );
    final noteController = TextEditingController(
      text: tx.note,
    );
    String type = tx.type;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('İşlemi Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'İşlem Türü',
                        prefixIcon: Icon(Icons.swap_horiz),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'deposit',
                          child: Text('Para Ekle'),
                        ),
                        DropdownMenuItem(
                          value: 'withdraw',
                          child: Text('Para Çek'),
                        ),
                      ],
                      onChanged: (val) {
                        type = val ?? 'deposit';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Not',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () async {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Geçerli bir tutar gir.'),
                        ),
                      );
                      return;
                    }

                    setState(() => isSaving = true);

                    final updated = BankrollTransaction(
                      id: tx.id,
                      userId: tx.userId,
                      amount: amount,
                      type: type,
                      note: noteController.text.trim(),
                      createdAt: tx.createdAt,
                    );

                    final result =
                    await BankrollService.updateTransaction(updated);

                    if (!context.mounted) return;

                    setState(() => isSaving = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İşlem güncellendi.'),
                      ),
                    );
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Güncelle'),
                ),
                ElevatedButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () async {
                    if (tx.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silinecek işlem bulunamadı.'),
                        ),
                      );
                      return;
                    }

                    setState(() => isDeleting = true);

                    final result =
                    await BankrollService.deleteTransaction(
                      userId: tx.userId,
                      transactionId: tx.id!,
                    );

                    if (!context.mounted) return;

                    setState(() => isDeleting = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İşlem silindi.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Sil'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}