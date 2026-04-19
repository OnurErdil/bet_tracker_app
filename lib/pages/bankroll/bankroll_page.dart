import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: AppStyles.cardShape(radius: AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.30),
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Kasa hareketleri yüklenemedi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: AppStyles.cardShape(radius: AppRadius.lg),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surfaceAlt,
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Henüz işlem yok',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'İlk kasa hareketini eklediğinde burada listelenecek.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final tx = list[i];

              final isDeposit = tx.type == 'deposit';
              final accentColor =
              isDeposit ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

              return Card(
                color: AppColors.surface,
                elevation: 0,
                shape: AppStyles.cardShape(radius: AppRadius.lg),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => _showEditDialog(context, tx),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: accentColor.withOpacity(0.32),
                            ),
                          ),
                          child: Icon(
                            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.note.trim().isEmpty ? 'İşlem' : tx.note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${isDeposit ? 'Para Eklendi' : 'Para Çekildi'}\n${_formatDate(tx.createdAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${isDeposit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
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
              backgroundColor: AppColors.surface,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
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
              backgroundColor: AppColors.surface,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
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