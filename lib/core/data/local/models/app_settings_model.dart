import 'package:hive/hive.dart';
part 'app_settings_model.g.dart';

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

  @HiveField(7)
  final String? hmacSignature;

  @HiveField(8)
  final String subscriptionMode; // 'fixed_28' | 'fixed_30' | 'calendar_month'


  AppSettings({
    this.gstRate = 18.0,
    this.expiryReminderDays = 3,
    this.whatsappReminders = true,
    this.biometricEnabled = false,
    this.useBiometrics = false,
    this.businessType = 'Gym',
    this.lastBackupAt,
    this.hmacSignature,
    this.subscriptionMode = 'calendar_month',
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
      hmacSignature: data['hmacSignature'],
      subscriptionMode: data['subscriptionMode'] ?? 'calendar_month',
    );
  }

  factory AppSettings.fromDrift(dynamic d) {
    return AppSettings(
      gstRate: d.gstRate,
      expiryReminderDays: d.expiryReminderDays,
      whatsappReminders: d.whatsappReminders,
      biometricEnabled: d.biometricEnabled,
      useBiometrics: d.useBiometrics,
      businessType: d.businessType,
      lastBackupAt: d.lastBackupAt,
      hmacSignature: d.hmacSignature,
      subscriptionMode: d.subscriptionMode,
    );
  }

  Map<String, dynamic> toJson() => toFirestore();

  Map<String, dynamic> toFirestore() {
    return {
      'gstRate': gstRate,
      'expiryReminderDays': expiryReminderDays,
      'whatsappReminders': whatsappReminders,
      'biometricEnabled': biometricEnabled,
      'useBiometrics': useBiometrics,
      'businessType': businessType,
      'lastBackupAt': lastBackupAt?.toIso8601String(),
      'hmacSignature': hmacSignature,
      'subscriptionMode': subscriptionMode,
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
    String? hmacSignature,
    String? subscriptionMode,
  }) {
    return AppSettings(
      gstRate: gstRate ?? this.gstRate,
      expiryReminderDays: expiryReminderDays ?? this.expiryReminderDays,
      whatsappReminders: whatsappReminders ?? this.whatsappReminders,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      businessType: businessType ?? this.businessType,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      hmacSignature: hmacSignature ?? this.hmacSignature,
      subscriptionMode: subscriptionMode ?? this.subscriptionMode,
    );
  }
}









