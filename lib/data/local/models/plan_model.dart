import 'package:hive/hive.dart';
import 'plan_component_model.dart';

@HiveType(typeId: 2)
class Plan extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late int durationMonths;
  @HiveField(3)
  late List<PlanComponent> components;
  @HiveField(4)
  late bool active;

  Plan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.components,
    this.active = true,
  });

  double get totalPrice => components.fold(0, (sum, c) => sum + c.price);
}
