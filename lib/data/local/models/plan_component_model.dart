import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class PlanComponent extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name; // e.g. "Gym Access", "Locker"
  @HiveField(2)
  late double price;

  PlanComponent({required this.id, required this.name, required this.price});
}
