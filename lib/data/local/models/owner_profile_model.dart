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
  });
}
