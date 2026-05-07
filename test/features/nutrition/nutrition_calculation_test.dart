import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/nutrition/domain/utils/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator Tests', () {
    test('calculateScaled should correctly scale calories', () {
      expect(NutritionCalculator.calculateScaled(100, 200), 200.0);
      expect(NutritionCalculator.calculateScaled(50, 100), 50.0);
      expect(NutritionCalculator.calculateScaled(165, 150), 247.5);
    });

    test('calculateScaled should clamp negative inputs', () {
      expect(NutritionCalculator.calculateScaled(-100, 200), 0.0);
      expect(NutritionCalculator.calculateScaled(100, -50), 0.0);
    });

    test('calculateScaled should clamp excessive inputs', () {
      // Assuming max 10000g portion as a sanity check
      expect(NutritionCalculator.calculateScaled(100, 100000), 10000.0); 
    });

    test('calculateAdherence should return 1.0 if under or at goal', () {
      expect(NutritionCalculator.calculateAdherence(1500, 2000), 1.0);
      expect(NutritionCalculator.calculateAdherence(2000, 2000), 1.0);
    });

    test('calculateAdherence should return percentage remaining if over goal', () {
      // 2500 consumed, 2000 goal -> 500 over -> 1.0 - (500/2000) = 0.75
      expect(NutritionCalculator.calculateAdherence(2500, 2000), 0.75);
    });

    test('calculateAdherence should return 0.0 if way over goal', () {
      expect(NutritionCalculator.calculateAdherence(5000, 2000), 0.0);
    });
  });
}
