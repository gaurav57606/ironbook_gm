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

  @HiveField(5)
  String? hmacSignature;

  Plan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.components,
    this.active = true,
    this.hmacSignature,
  });

  factory Plan.fromFirestore(Map<String, dynamic> data) {
    return Plan(
      id: data['id'],
      name: data['name'],
      durationMonths: data['durationMonths'],
      active: data['active'] ?? true,
      components: (data['components'] as List).map((c) => PlanComponent(
        id: c['id'],
        name: c['name'],
        price: (c['price'] as num).toDouble(),
      )).toList(),
    );
  }

  double get totalPrice => components.fold(0, (sum, c) => sum + c.price);

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'durationMonths': durationMonths,
      'active': active,
      'components': components.map((c) => {
        'id': c.id,
        'name': c.name,
        'price': c.price,
      }).toList(),
    };
  }
}
