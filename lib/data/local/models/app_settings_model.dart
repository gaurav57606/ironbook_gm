import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  late double gstRate; // default 18.0
  @HiveField(1)
  late int expiryReminderDays; // default 7
  @HiveField(2)
  late bool whatsappReminders;
  @HiveField(3)
  final bool biometricEnabled; // Keep for legacy if needed

  @HiveField(5)
  final bool useBiometrics;

  @HiveField(4)
  final String businessType; // 'gym' | 'library' | 'salon' | 'custom'

  @HiveField(6)
  final bool auditMode;

  AppSettings({
    this.gstRate = 18.0,
    this.expiryReminderDays = 3,
    this.whatsappReminders = true,
    this.biometricEnabled = false,
    this.useBiometrics = false,
    this.businessType = 'Gym',
    this.auditMode = false,
  });

  AppSettings copyWith({
    double? gstRate,
    int? expiryReminderDays,
    bool? whatsappReminders,
    bool? biometricEnabled,
    bool? useBiometrics,
    String? businessType,
    bool? auditMode,
  }) {
    return AppSettings(
      gstRate: gstRate ?? this.gstRate,
      expiryReminderDays: expiryReminderDays ?? this.expiryReminderDays,
      whatsappReminders: whatsappReminders ?? this.whatsappReminders,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      businessType: businessType ?? this.businessType,
      auditMode: auditMode ?? this.auditMode,
    );
  }
}
