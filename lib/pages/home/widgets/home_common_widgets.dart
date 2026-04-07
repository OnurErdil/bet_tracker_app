import 'package:bet_tracker_app/models/bet_model.dart';
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

class WelcomeHeader extends StatelessWidget {
  final String email;

  const WelcomeHeader({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.verified_user,
              size: 56,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoş geldin',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bugünkü tabloya bak, bekleyen bahisleri kapat, sonra keyfine bak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
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
              child: Icon(
                icon,
                color: const Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
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
        minimumSize: const Size(180, 48),
        side: const BorderSide(color: Color(0xFF2A3140)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
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