import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
      ),
      body: StreamBuilder<List<BankrollTransaction>>(
        stream: BankrollService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorStateCard(
              message:
              'Kasa hareketleri yüklenemedi:\n${snapshot.error}',
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: const InfoCard(
                  text:
                  'Henüz işlem yok.\nİlk kasa hareketini eklediğinde burada listelenecek.',
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
              final accentTone =
              isDeposit ? StatusTone.success : StatusTone.danger;
              final accentColor = statusToneColor(accentTone);

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
                            color: statusToneFill(accentTone),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: statusToneBorder(accentTone),
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
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  BetInfoChip(
                                    icon: isDeposit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    text: isDeposit
                                        ? 'Para Eklendi'
                                        : 'Para Çekildi',
                                    tone: isDeposit
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  ),
                                  BetInfoChip(
                                    icon: Icons.schedule_outlined,
                                    text: _formatDate(tx.createdAt),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        BetInfoChip(
                          icon: isDeposit
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          text:
                          '${isDeposit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ₺',
                          tone: isDeposit
                              ? StatusTone.success
                              : StatusTone.danger,
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

  static ButtonStyle _dialogButtonStyle({
    required Color backgroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  static ButtonStyle _primaryDialogButtonStyle() {
    return _dialogButtonStyle(
      backgroundColor: AppColors.primary,
    );
  }

  static ButtonStyle _dangerDialogButtonStyle() {
    return _dialogButtonStyle(
      backgroundColor: AppColors.danger,
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Widget _buildDialogHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    StatusTone tone = StatusTone.primary,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusToneFill(tone),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: statusToneBorder(tone),
            ),
          ),
          child: Icon(
            icon,
            color: statusToneColor(tone),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildTransactionAmountField({
    required TextEditingController controller,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: 'Tutar',
        hintText: hintText,
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
    );
  }

  static Widget _buildTransactionTypeField({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
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
      onChanged: onChanged,
    );
  }

  static Widget _buildTransactionNoteField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Not',
        hintText: 'Örn: Nakit ekleme / çekim nedeni',
        prefixIcon: Icon(Icons.note_alt_outlined),
      ),
    );
  }

  static double? _parseAmount(TextEditingController controller) {
    return double.tryParse(
      controller.text.trim().replaceAll(',', '.'),
    );
  }

  static Widget _buildDialogLoadingChild() {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }

  static Widget _buildDialogActionLabel({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
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
              title: _buildDialogHeader(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Yeni İşlem',
                subtitle: 'Kasaya para ekle veya çekme işlemi oluştur.',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTransactionAmountField(
                      controller: amountController,
                      hintText: 'Örn: 1000',
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionTypeField(
                      value: type,
                      onChanged: (val) {
                        setState(() {
                          type = val ?? 'deposit';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionNoteField(
                      controller: noteController,
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
                    final amount = _parseAmount(amountController);

                    if (user == null) {
                      _showMessage(context, 'Kullanıcı bulunamadı.');
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      _showMessage(context, 'Geçerli bir tutar gir.');
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
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(context, 'İşlem eklendi.');
                  },
                  style: _primaryDialogButtonStyle(),
                  child: isSaving
                      ? _buildDialogLoadingChild()
                      : _buildDialogActionLabel(
                    icon: Icons.save_outlined,
                    label: 'Kaydet',
                  ),
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
              title: _buildDialogHeader(
                icon: Icons.edit_outlined,
                title: 'İşlemi Düzenle',
                subtitle: 'Kasa hareketini güncelle veya sil.',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTransactionAmountField(
                      controller: amountController,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionTypeField(
                      value: type,
                      onChanged: (val) {
                        setState(() {
                          type = val ?? 'deposit';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionNoteField(
                      controller: noteController,
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
                    final amount = _parseAmount(amountController);

                    if (amount == null || amount <= 0) {
                      _showMessage(context, 'Geçerli bir tutar gir.');
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
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(context, 'İşlem güncellendi.');
                  },
                  style: _primaryDialogButtonStyle(),
                  child: isSaving
                      ? _buildDialogLoadingChild()
                      : _buildDialogActionLabel(
                    icon: Icons.edit_outlined,
                    label: 'Güncelle',
                  ),
                ),
                ElevatedButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () async {
                    if (tx.id == null) {
                      _showMessage(context, 'Silinecek işlem bulunamadı.');
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
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(context, 'İşlem silindi.');
                  },
                  style: _dangerDialogButtonStyle(),
                  child: isDeleting
                      ? _buildDialogLoadingChild()
                      : _buildDialogActionLabel(
                    icon: Icons.delete_outline,
                    label: 'Sil',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}