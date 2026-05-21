import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/member_provider.dart';
import '../providers/owner_provider.dart';
import '../providers/settings_provider.dart';
import '../../shared/utils/clock.dart';
import '../../shared/utils/date_utils.dart';

/// Reads the whatsappReminders setting and opens WhatsApp for each
/// member whose membership expires in exactly [settings.expiryReminderDays] days.
/// Must be called from a UI context (e.g. app resume) — it launches external URLs.
class ReminderService {
  static Future<void> sendWhatsAppReminders(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (!settings.whatsappReminders) return;

    final now = ref.read(clockProvider.select((c) => c.now));
    final members = ref.read(membersProvider);
    final owner = ref.read(ownerProvider);
    final gymName = owner?.gymName ?? 'your gym';
    final threshold = settings.expiryReminderDays;

    for (final member in members) {
      final daysLeft = member.getDaysRemaining(now);
      final phone = member.phone;

      if (daysLeft != threshold) continue;
      if (phone == null || phone.trim().isEmpty) continue;

      final clean = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      final dialCode = clean.startsWith('91') ? clean : '91$clean';
      final expiry = member.expiryDate != null
          ? AppDateUtils.format(member.expiryDate!)
          : 'soon';

      final msg = Uri.encodeComponent(
        'Hi ${member.name}, your membership at $gymName expires on $expiry ($daysLeft days left). Please renew to keep your fitness going! 💪',
      );

      final url = Uri.parse('https://wa.me/$dialCode?text=$msg');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Small delay between sequential opens to avoid OS throttle
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }
}
