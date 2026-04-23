import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class BetLockedWarningCard extends StatelessWidget {
  final String message;

  const BetLockedWarningCard({
    super.key,
    this.message = 'Bugün bahis kilitli. Disiplin modu aktif.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusToneFill(StatusTone.danger),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: statusToneBorder(StatusTone.danger),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textDangerSoft,
        ),
      ),
    );
  }
}

class BetDisciplineInfoCard extends StatelessWidget {
  final String maxStakeInfoText;
  final int confidenceScore;
  final bool isHighConfidenceSelected;
  final double effectiveMaxStake;
  final double dailyLossLimit;
  final double targetBankroll;
  final double todayLoss;
  final String disciplineModeLabel;

  const BetDisciplineInfoCard({
    super.key,
    required this.maxStakeInfoText,
    required this.confidenceScore,
    required this.isHighConfidenceSelected,
    required this.effectiveMaxStake,
    required this.dailyLossLimit,
    required this.targetBankroll,
    required this.todayLoss,
    required this.disciplineModeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusToneFill(StatusTone.primary),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: statusToneBorder(StatusTone.primary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktif Disiplin Kuralları',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (maxStakeInfoText.isNotEmpty) Text(maxStakeInfoText),
          Text('• Güven puanı: $confidenceScore / 10'),
          if (isHighConfidenceSelected && effectiveMaxStake > 0)
            Text(
              '• Bu güven için izin verilen üst limit: ${effectiveMaxStake.toStringAsFixed(2)} ₺',
            ),
          if (dailyLossLimit > 0)
            Text(
              '• Günlük kayıp limiti: ${dailyLossLimit.toStringAsFixed(2)} ₺',
            ),
          if (targetBankroll > 0)
            Text(
              '• Hedef kasa: ${targetBankroll.toStringAsFixed(2)} ₺',
            ),
          if (dailyLossLimit > 0)
            Text(
              '• Bugünkü gerçekleşmiş kayıp: ${todayLoss.toStringAsFixed(2)} ₺',
            ),
          Text(disciplineModeLabel),
        ],
      ),
    );
  }
}

class BetLivePreviewCard extends StatelessWidget {
  final String previewResultLabel;
  final double netProfit;
  final StatusTone netTone;
  final double payout;
  final double effectiveMaxStake;
  final bool isPreviewLimitExceeded;
  final String payoutLabel;

  const BetLivePreviewCard({
    super.key,
    required this.previewResultLabel,
    required this.netProfit,
    required this.netTone,
    required this.payout,
    required this.effectiveMaxStake,
    required this.isPreviewLimitExceeded,
    this.payoutLabel = 'Toplam Geri Ödeme',
  });

  @override
  Widget build(BuildContext context) {
    final containerTone =
    isPreviewLimitExceeded ? StatusTone.danger : StatusTone.info;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPreviewLimitExceeded
            ? statusToneFill(containerTone)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPreviewLimitExceeded
              ? statusToneBorder(containerTone)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Canlı Hesap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BetInfoChip(
                icon: Icons.visibility_outlined,
                text: previewResultLabel,
                tone: StatusTone.info,
              ),
              BetInfoChip(
                icon: netProfit >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                text: 'Net ${netProfit.toStringAsFixed(2)} ₺',
                tone: netTone,
              ),
              BetInfoChip(
                icon: Icons.account_balance_wallet_outlined,
                text: '$payoutLabel: ${payout.toStringAsFixed(2)} ₺',
                tone: StatusTone.info,
              ),
              if (effectiveMaxStake > 0)
                BetInfoChip(
                  icon: Icons.money_off_csred_outlined,
                  text: 'Max ${effectiveMaxStake.toStringAsFixed(2)} ₺',
                  tone: StatusTone.warning,
                ),
            ],
          ),
          if (isPreviewLimitExceeded) ...[
            const SizedBox(height: 8),
            const BetInfoChip(
              icon: Icons.warning_amber_rounded,
              text: 'Maksimum bahis limiti aşıldı',
              tone: StatusTone.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class BetConfidenceScoreCard extends StatelessWidget {
  final int confidenceScore;
  final bool isHighConfidenceSelected;
  final double effectiveMaxStake;
  final ValueChanged<double> onChanged;

  const BetConfidenceScoreCard({
    super.key,
    required this.confidenceScore,
    required this.isHighConfidenceSelected,
    required this.effectiveMaxStake,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentTone = isHighConfidenceSelected
        ? StatusTone.warning
        : StatusTone.primary;
    final accentColor = statusToneColor(accentTone);

    final helperText = isHighConfidenceSelected && effectiveMaxStake > 0
        ? 'Yüksek güven aktif • Bu seçim için max: ${effectiveMaxStake.toStringAsFixed(2)} ₺'
        : 'Normal güven • Standart maksimum limit geçerli';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: statusToneBorder(accentTone),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Güven Puanı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusToneFill(accentTone),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: statusToneBorder(accentTone),
                  ),
                ),
                child: Text(
                  '$confidenceScore / 10',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.border,
              thumbColor: accentColor,
              overlayColor: statusToneFill(accentTone),
              valueIndicatorColor: accentColor,
            ),
            child: Slider(
              value: confidenceScore.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: confidenceScore.toString(),
              onChanged: onChanged,
            ),
          ),
          Text(
            helperText,
            style: TextStyle(
              color: isHighConfidenceSelected
                  ? accentColor
                  : AppColors.textSecondary,
              fontWeight: isHighConfidenceSelected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}