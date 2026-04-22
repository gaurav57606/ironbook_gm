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
  final DateTime? lastBackupAt;


  AppSettings({
    this.gstRate = 18.0,
    this.expiryReminderDays = 3,
    this.whatsappReminders = true,
    this.biometricEnabled = false,
    this.useBiometrics = false,
    this.businessType = 'Gym',
    this.lastBackupAt,
  });

  factory AppSettings.fromFirestore(Map<String, dynamic> data) {
    return AppSettings(
      gstRate: (data['gstRate'] as num?)?.toDouble() ?? 18.0,
      expiryReminderDays: data['expiryReminderDays'] ?? 3,
      whatsappReminders: data['whatsappReminders'] ?? true,
      biometricEnabled: data['biometricEnabled'] ?? false,
      useBiometrics: data['useBiometrics'] ?? false,
      businessType: data['businessType'] ?? 'Gym',
      lastBackupAt: data['lastBackupAt'] != null ? DateTime.parse(data['lastBackupAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gstRate': gstRate,
      'expiryReminderDays': expiryReminderDays,
      'whatsappReminders': whatsappReminders,
      'biometricEnabled': biometricEnabled,
      'useBiometrics': useBiometrics,
      'businessType': businessType,
      'lastBackupAt': lastBackupAt?.toIso8601String(),
    };
  }

  AppSettings copyWith({
    double? gstRate,
    int? expiryReminderDays,
    bool? whatsappReminders,
    bool? biometricEnabled,
    bool? useBiometrics,
    String? businessType,
    DateTime? lastBackupAt,
  }) {
    return AppSettings(
      gstRate: gstRate ?? this.gstRate,
      expiryReminderDays: expiryReminderDays ?? this.expiryReminderDays,
      whatsappReminders: whatsappReminders ?? this.whatsappReminders,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      businessType: businessType ?? this.businessType,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}
