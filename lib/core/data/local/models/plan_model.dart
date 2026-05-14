import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  @HiveField(6)
  late double price;

  Plan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.components,
    required this.price,
    this.active = true,
    this.hmacSignature,
  });

  factory Plan.fromFirestore(Map<String, dynamic> data) {
    final comps = (data['components'] as List? ?? []).map((c) => PlanComponent(
      id: c['id'],
      name: c['name'],
      price: (c['price'] as num).toDouble(),
    )).toList();

    return Plan(
      id: data['id'],
      name: data['name'],
      durationMonths: data['durationMonths'],
      active: data['active'] ?? true,
      price: (data['price'] as num?)?.toDouble() ?? 
             comps.fold(0.0, (sum, c) => sum + c.price),
      components: comps,
    );
  }

  double get totalPrice => price;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'durationMonths': durationMonths,
      'active': active,
      'price': price,
      'components': components.map((c) => {
        'id': c.id,
        'name': c.name,
        'price': c.price,
      }).toList(),
      'hmacSignature': hmacSignature,
    };
  }

  factory Plan.fromDrift(dynamic d) {
    List<PlanComponent> comps = [];
    if (d.componentsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(d.componentsJson);
        comps = decoded.map((c) => PlanComponent(
          id: c['id'] ?? '',
          name: c['name'] ?? '',
          price: (c['price'] as num?)?.toDouble() ?? 0.0,
        )).toList();
      } catch (e) {
        debugPrint('Error decoding plan componentsJson: $e');
      }
    }

    final priceVal = d.price > 0 ? d.price : comps.fold(0.0, (sum, c) => sum + c.price);

    return Plan(
      id: d.id,
      name: d.name,
      durationMonths: d.durationMonths,
      active: d.active,
      price: priceVal,
      components: comps,
      hmacSignature: d.hmacSignature,
    );
  }
}









