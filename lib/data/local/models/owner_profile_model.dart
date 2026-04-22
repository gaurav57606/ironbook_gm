import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class OwnerProfile extends HiveObject {
  @HiveField(0)
  late String gymName;
  @HiveField(1)
  late String ownerName;
  @HiveField(2)
  late String phone;
  @HiveField(3)
  late String address;
  @HiveField(4)
  String? gstin;
  @HiveField(5)
  String? bankName;
  @HiveField(6)
  String? accountNumber;
  @HiveField(7)
  String? ifsc;
  @HiveField(8)
  String? upiId;
  @HiveField(9)
  String? logoPath; // local file path

  @HiveField(10)
  String? hmacSignature;

  @HiveField(11)
  int level;

  @HiveField(12)
  int exp;

  @HiveField(13)
  double strength;

  @HiveField(14)
  double endurance;

  @HiveField(15)
  double dexterity;

  @HiveField(16)
  String selectedCharacterId;

  OwnerProfile({
    required this.gymName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.gstin,
    this.bankName,
    this.accountNumber,
    this.ifsc,
    this.upiId,
    this.logoPath,
    this.hmacSignature,
    this.level = 1,
    this.exp = 0,
    this.strength = 0.5,
    this.endurance = 0.5,
    this.dexterity = 0.5,
    this.selectedCharacterId = 'warrior',
  });

  factory OwnerProfile.fromFirestore(Map<String, dynamic> data) {
    return OwnerProfile(
      gymName: data['gymName'],
      ownerName: data['ownerName'],
      phone: data['phone'],
      address: data['address'],
      gstin: data['gstin'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      ifsc: data['ifsc'],
      upiId: data['upiId'],
      level: data['level'] ?? 1,
      exp: data['exp'] ?? 0,
      strength: (data['strength'] as num?)?.toDouble() ?? 0.5,
      endurance: (data['endurance'] as num?)?.toDouble() ?? 0.5,
      dexterity: (data['dexterity'] as num?)?.toDouble() ?? 0.5,
      selectedCharacterId: data['selectedCharacterId'] ?? 'warrior',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gymName': gymName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'upiId': upiId,
      'level': level,
      'exp': exp,
      'strength': strength,
      'endurance': endurance,
      'dexterity': dexterity,
      'selectedCharacterId': selectedCharacterId,
    };
  }
}
