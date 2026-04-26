import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

void showAppSnackBar(
    BuildContext context,
    String message, {
      bool clearPrevious = false,
    }) {
  final messenger = ScaffoldMessenger.of(context);

  if (clearPrevious) {
    messenger.clearSnackBars();
  }

  messenger.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

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

Color homeSuccessColor() => const Color(0xFF22C55E);
Color homeDangerColor() => const Color(0xFFEF4444);
Color homeWarningColor() => const Color(0xFFF59E0B);
Color homeMutedColor() => const Color(0xFF94A3B8);
Color homeInfoColor() => const Color(0xFF0EA5E9);
Color homeHighConfidenceColor() => const Color(0xFFEA580C);

enum StatusTone {
  primary,
  success,
  danger,
  warning,
  muted,
  info,
  highConfidence,
}

StatusTone betResultTone(String value) {
  switch (value) {
    case 'kazandi':
      return StatusTone.success;
    case 'kaybetti':
      return StatusTone.danger;
    case 'iade':
      return StatusTone.warning;
    case 'beklemede':
    default:
      return StatusTone.muted;
  }
}

Color statusToneColor(StatusTone tone) {
  switch (tone) {
    case StatusTone.primary:
      return AppColors.primary;
    case StatusTone.success:
      return homeSuccessColor();
    case StatusTone.danger:
      return homeDangerColor();
    case StatusTone.warning:
      return homeWarningColor();
    case StatusTone.muted:
      return homeMutedColor();
    case StatusTone.info:
      return homeInfoColor();
    case StatusTone.highConfidence:
      return homeHighConfidenceColor();
  }
}

Color statusToneFill(StatusTone tone) {
  return statusToneColor(tone).withValues(alpha: 0.14);
}

Color statusToneBorder(StatusTone tone) {
  return statusToneColor(tone).withValues(alpha: 0.35);
}

ButtonStyle solidToneButtonStyle({
  required StatusTone tone,
  Size minimumSize = const Size(0, 46),
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
  double radius = AppRadius.md,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: statusToneColor(tone),
    foregroundColor: Colors.white,
    minimumSize: minimumSize,
    padding: padding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

StatusTone confidenceBadgeTone(int score) {
  if (score >= 10) return StatusTone.highConfidence;
  if (score >= 9) return StatusTone.warning;
  if (score >= 7) return StatusTone.success;
  if (score >= 5) return StatusTone.info;
  return StatusTone.muted;
}

Color confidenceBadgeColor(int score) {
  return statusToneColor(confidenceBadgeTone(score));
}

class ConfidenceBadge extends StatelessWidget {
  final int score;

  const ConfidenceBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final tone = confidenceBadgeTone(score);
    final color = statusToneColor(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusToneFill(tone),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: statusToneBorder(tone),
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
                color: statusToneFill(StatusTone.primary),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: statusToneBorder(StatusTone.primary),
                ),
              ),
              child: Icon(
                Icons.verified_user,
                size: 34,
                color: statusToneColor(StatusTone.primary),
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
  final StatusTone? iconTone;
  final bool centered;
  final bool compact;

  const StatValueCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.valueColor,
    this.iconTone,
    this.centered = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor ?? AppColors.textPrimary;
    final resolvedIconTone = iconTone ?? StatusTone.primary;
    final resolvedIconColor = statusToneColor(resolvedIconTone);
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
          color: statusToneFill(resolvedIconTone),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: statusToneBorder(resolvedIconTone),
          ),
        ),
        child: Icon(
          icon,
          color: resolvedIconColor,
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
  final StatusTone? iconTone;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconTone,
  });

  @override
  Widget build(BuildContext context) {
    return StatValueCard(
      title: title,
      value: value,
      icon: icon,
      valueColor: valueColor,
      iconTone: iconTone,
    );
  }
}

class FormSequenceEntry {
  final String label;
  final Color? color;
  final StatusTone? tone;

  const FormSequenceEntry({
    required this.label,
    this.color,
    this.tone,
  }) : assert(color != null || tone != null);

  Color get resolvedColor {
    return color ?? statusToneColor(tone!);
  }
}

class FormSequenceCard extends StatelessWidget {
  final String title;
  final List<FormSequenceEntry> items;

  const FormSequenceCard({
    super.key,
    this.title = 'Son 10 Form',
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusToneFill(StatusTone.primary),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: statusToneBorder(StatusTone.primary),
                    ),
                  ),
                  child: Icon(
                    Icons.insights_outlined,
                    color: statusToneColor(StatusTone.primary),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Henüz form verisi yok',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  final resolvedColor = item.resolvedColor;
                  final resolvedTone = item.tone;

                  return Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: resolvedTone != null
                          ? statusToneFill(resolvedTone)
                          : resolvedColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: resolvedTone != null
                            ? statusToneBorder(resolvedTone)
                            : resolvedColor.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: resolvedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class Last10FormCard extends StatelessWidget {
  final List<BetModel> bets;

  const Last10FormCard({
    super.key,
    required this.bets,
  });

  List<FormSequenceEntry> _buildItems() {
    return bets.map((bet) {
      switch (bet.result) {
        case 'kazandi':
          return const FormSequenceEntry(
            label: 'W',
            tone: StatusTone.success,
          );
        case 'kaybetti':
          return const FormSequenceEntry(
            label: 'L',
            tone: StatusTone.danger,
          );
        case 'iade':
          return const FormSequenceEntry(
            label: 'I',
            tone: StatusTone.warning,
          );
        default:
          return const FormSequenceEntry(
            label: 'B',
            tone: StatusTone.muted,
          );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FormSequenceCard(
      items: _buildItems(),
    );
  }
}

class ButtonLoadingIndicator extends StatelessWidget {
  final double size;

  const ButtonLoadingIndicator({
    super.key,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}

class ButtonIconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const ButtonIconLabel({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final StatusTone tone;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = StatusTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusToneColor(tone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: statusToneFill(tone),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: statusToneBorder(tone),
              ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class AppDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final StatusTone tone;

  const AppDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = StatusTone.primary,
  });

  @override
  Widget build(BuildContext context) {
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
            color: statusToneColor(StatusTone.primary),
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

class SummaryInsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Color? valueColor;
  final StatusTone? tone;

  const SummaryInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor ??
        (tone == null ? AppColors.textPrimary : statusToneColor(tone!));

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: AppRadius.lg),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
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
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: resolvedValueColor,
              ),
            ),
          ],
        ),
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

class SectionCardShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCardShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class BetCardShell extends StatelessWidget {
  final String title;
  final int confidenceScore;
  final Widget child;
  final VoidCallback? onTap;
  final double titleFontSize;
  final EdgeInsetsGeometry padding;

  const BetCardShell({
    super.key,
    required this.title,
    required this.confidenceScore,
    required this.child,
    this.onTap,
    this.titleFontSize = 16,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConfidenceBadge(score: confidenceScore),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: AppRadius.lg),
      margin: const EdgeInsets.only(bottom: 12),
      child: onTap == null
          ? content
          : InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class BetInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final StatusTone? tone;

  const BetInfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
    tone == null ? AppColors.textSecondary : statusToneColor(tone!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: tone == null ? AppColors.surfaceAlt : statusToneFill(tone!),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: tone == null ? AppColors.border : statusToneBorder(tone!),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: resolvedColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: resolvedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final StatusTone tone;
  final VoidCallback? onPressed;

  const StatusActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: solidToneButtonStyle(
        tone: tone,
        minimumSize: const Size(0, 44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const SecondaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        backgroundColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class StateMessageCard extends StatelessWidget {
  final String text;
  final StatusTone tone;
  final IconData icon;
  final bool centered;

  const StateMessageCard({
    super.key,
    required this.text,
    required this.tone,
    required this.icon,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusToneColor(tone);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusToneFill(tone),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: statusToneBorder(tone),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: centered ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                color: tone == StatusTone.danger
                    ? AppColors.textDangerSoft
                    : AppColors.textPrimary,
                fontWeight: tone == StatusTone.danger
                    ? FontWeight.bold
                    : FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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
    return StateMessageCard(
      text: text,
      tone: StatusTone.info,
      icon: Icons.info_outline,
    );
  }
}

class WarningCard extends StatelessWidget {
  final String message;

  const WarningCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessageCard(
      text: message,
      tone: StatusTone.danger,
      icon: Icons.warning_amber_rounded,
      centered: false,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: StateMessageCard(
          text: message,
          tone: StatusTone.danger,
          icon: Icons.error_outline,
        ),
      ),
    );
  }
}