import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 70, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.elevation1,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  content,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.8,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Last Updated: May 2026',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String privacyPolicyContent = """
PRIVACY POLICY

1. INFORMATION WE COLLECT
IronBook GM ("the App") is designed as a local-first application. We collect:
• Owner Profile Data: Name, Gym Name, Address, and Contact details to generate invoices.
• Member Data: Name, Contact, and Membership details stored locally on your device and synchronized with our secure cloud servers.
• Device Data: Unique installation ID for HMAC security verification.

2. HOW WE USE DATA
Your data is used exclusively to:
• Facilitate gym management and member tracking.
• Provide secure cloud backup and multi-device synchronization.
• Generate professional PDF invoices.
• Enforce security protocols using HMAC signatures.

3. DATA SECURITY
We implement industry-standard encryption. Every piece of sensitive data is signed with an HMAC-SHA256 signature to prevent unauthorized tampering.

4. THIRD-PARTY SERVICES
We use Google Firebase for:
• Authentication (secure login).
• Firestore (encrypted cloud synchronization).

5. YOUR RIGHTS
You have the right to export your data (CSV) or wipe your account at any time through the Settings menu.

6. CONTACT
For privacy concerns, contact support@ironbook.gm
""";

  static const String termsOfServiceContent = """
TERMS OF SERVICE

1. ACCEPTANCE OF TERMS
By using IronBook GM, you agree to these professional standards and terms.

2. LICENSE
We grant you a personal, non-transferable license to use the App for gym management purposes.

3. SUBSCRIPTIONS
• Subscription "Leases" are required for continued access to the App.
• Payments are processed securely.
• Failure to maintain an active lease may result in read-only access.

4. DATA INTEGRITY
IronBook GM uses an event-sourcing architecture. While we strive for 100% data integrity, you are encouraged to use the "Export CSV" feature regularly for local backups.

5. PROHIBITED USES
You may not attempt to reverse-engineer the App, bypass security guards, or manipulate the HMAC signatures.

6. LIMITATION OF LIABILITY
IronBook GM is provided "as is". We are not liable for any data loss resulting from unauthorized device modification (rooting/jailbreaking) or failure to sync changes.

7. TERMINATION
We reserve the right to modify these terms at any time.
""";
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Privacy Policy',
      content: LegalScreen.privacyPolicyContent,
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Terms of Service',
      content: LegalScreen.termsOfServiceContent,
    );
  }
}
