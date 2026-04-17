import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

String resultLabel(String value) {
  switch (value) {
    case 'kazandi':
      return 'Kazandı';
    case 'kaybetti':
      return 'Kaybetti';
    case 'iade':
      return 'İade';
    case 'Tümü':
      return 'Tümü';
    default:
      return 'Beklemede';
  }
}

String disciplineModeText(String mode) {
  switch (mode) {
    case 'block_bet':
      return 'Bahsi Engelle';
    case 'lock_day':
      return 'Günü Kilitle';
    case 'warning':
    default:
      return 'Sadece Uyarı';
  }
}

Color confidenceBadgeColor(int score) {
  if (score >= 10) return const Color(0xFFEA580C);
  if (score >= 9) return const Color(0xFFF59E0B);
  if (score >= 7) return const Color(0xFF16A34A);
  if (score >= 5) return const Color(0xFF0EA5E9);
  return const Color(0xFF64748B);
}

class ConfidenceBadge extends StatelessWidget {
  final int score;

  const ConfidenceBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final color = confidenceBadgeColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Text(
            'G $score',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  final String email;

  const WelcomeHeader({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.30),
                ),
              ),
              child: const Icon(
                Icons.verified_user,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Bet Tracker',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Hoş geldin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Text(
                'Bugünkü tabloya bak, bekleyen bahisleri kapat, sonra keyfine bak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatValueCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool centered;
  final bool compact;

  const StatValueCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.valueColor,
    this.centered = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor ?? AppColors.textPrimary;
    final borderRadius = compact ? AppRadius.md : AppRadius.lg;
    final verticalPadding = compact ? AppSpacing.md : AppSpacing.lg;
    final horizontalPadding = compact ? AppSpacing.md : 18.0;
    final titleFontSize = compact ? 12.0 : 13.0;
    final valueFontSize = compact ? 17.0 : 18.0;

    Widget? buildLeadingIcon() {
      if (icon == null) return null;

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.28),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      );
    }

    final leadingIcon = buildLeadingIcon();

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: borderRadius),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: centered
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: valueFontSize,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: resolvedValueColor,
              ),
            ),
          ],
        )
            : Row(
          children: [
            if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: resolvedValueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return StatValueCard(
      title: title,
      value: value,
      icon: icon,
      valueColor: valueColor,
    );
  }
}

class Last10FormCard extends StatelessWidget {
  final List<BetModel> bets;

  const Last10FormCard({
    super.key,
    required this.bets,
  });

  @override
  Widget build(BuildContext context) {
    final formItems = bets.map((bet) {
      late final Color color;
      late final String label;

      switch (bet.result) {
        case 'kazandi':
          color = const Color(0xFF22C55E);
          label = 'W';
          break;
        case 'kaybetti':
          color = const Color(0xFFEF4444);
          label = 'L';
          break;
        case 'iade':
          color = const Color(0xFFF59E0B);
          label = 'I';
          break;
        default:
          color = const Color(0xFF94A3B8);
          label = 'B';
      }

      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();

    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
              child: const Icon(
                Icons.insights_outlined,
                color: Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son 10 Form',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: formItems.isEmpty
                        ? const [
                      Text(
                        '-',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]
                        : formItems,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(190, 52),
        backgroundColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: const Icon(
        Icons.circle,
        size: 0,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;

  const InfoCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ErrorStateCard extends StatelessWidget {
  final String message;

  const ErrorStateCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}