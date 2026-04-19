import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class BetLockedWarningCard extends StatelessWidget {
  final String text;

  const BetLockedWarningCard({
    super.key,
    this.text = 'Bugün bahis kilitli. Disiplin modu aktif.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
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
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
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
  final Color netColor;
  final double payout;
  final double effectiveMaxStake;
  final bool isPreviewLimitExceeded;
  final String payoutLabel;

  const BetLivePreviewCard({
    super.key,
    required this.previewResultLabel,
    required this.netProfit,
    required this.netColor,
    required this.payout,
    required this.effectiveMaxStake,
    required this.isPreviewLimitExceeded,
    this.payoutLabel = 'Toplam Geri Ödeme',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPreviewLimitExceeded
            ? AppColors.danger.withOpacity(0.12)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPreviewLimitExceeded
              ? AppColors.danger.withOpacity(0.35)
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
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('• Senaryo: $previewResultLabel'),
              Text(
                '• Net Etki: ${netProfit.toStringAsFixed(2)} ₺',
                style: TextStyle(
                  color: netColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '• $payoutLabel: ${payout.toStringAsFixed(2)} ₺',
              ),
            ],
          ),
          if (effectiveMaxStake > 0) ...[
            const SizedBox(height: 8),
            Text(
              '• Bu güven için maksimum bahis: ${effectiveMaxStake.toStringAsFixed(2)} ₺',
            ),
          ],
          if (isPreviewLimitExceeded) ...[
            const SizedBox(height: 8),
            const Text(
              '• Girilen tutar maksimum bahis limitini aşıyor.',
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontWeight: FontWeight.bold,
              ),
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
    final accentColor = isHighConfidenceSelected
        ? const Color(0xFFF59E0B)
        : AppColors.primary;

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
          color: accentColor.withOpacity(0.30),
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
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: accentColor.withOpacity(0.35),
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
              overlayColor: accentColor.withOpacity(0.12),
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