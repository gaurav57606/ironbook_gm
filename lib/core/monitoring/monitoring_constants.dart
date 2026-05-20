import 'package:flutter_dotenv/flutter_dotenv.dart';

class MonitoringConstants {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  
  static const String ownersTable = 'gym_owners';
  static const String membersTable = 'gym_members';
  static const String paymentEventsTable = 'payment_events';
  
  static const String usersTable = 'users_archive';
  static const String membershipsTable = 'memberships_archive';
  static const String paymentsTable = 'payments_archive';
  static const String activityTable = 'activity_logs';
  static const String auditTable = 'audit_logs';
  
  static const int maxQueueSize = 500;
  static const int maxRetries = 3;
  
  // Timer settings
  static const int senderIntervalSeconds = 25; // Send every 25 seconds
  static const Duration sendTimeout = Duration(seconds: 15);
}
