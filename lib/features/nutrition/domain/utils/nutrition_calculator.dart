import 'dart:math' as math;

/// Utility for calculating nutrition values based on portion sizes.
/// Hardened for production use with strict boundary checks.
class NutritionCalculator {
  /// Calculates scaled nutrition value based on grams.
  /// 
  /// [baseValue]: Nutrition per 100g.
  /// [grams]: The actual weight consumed.
  /// 
  /// Returns 0 if grams or baseValue is negative or zero.
  /// Rounds to 1 decimal place for precision.
  static double calculateScaled(double baseValue, double grams) {
    if (baseValue <= 0 || grams <= 0) return 0.0;
    
    // Protection against ridiculously large inputs (e.g., 100kg in one meal)
    // Max sensible input: 10,000g (10kg)
    final clampedGrams = math.min(grams, 10000.0);
    
    final result = (baseValue * clampedGrams) / 100.0;
    
    // Round to 1 decimal place
    return double.parse(result.toStringAsFixed(1));
  }

  /// Calculates adherence percentage (0.0 to 1.0).
  /// Penalizes exceeding the goal (e.g. 10% over -> 0.9 adherence).
  static double calculateAdherence(double consumed, double goal) {
    if (goal <= 0) return 0.0;
    if (consumed <= 0) return 1.0; // Adherence is high if nothing consumed yet? Or 0? Let's say 0 for tracker.
    
    if (consumed <= goal) {
      return 1.0; // At or under goal is perfect adherence for most diets
    } else {
      final excess = consumed - goal;
      final penalty = excess / goal;
      return math.max(0.0, 1.0 - penalty);
    }
  }
}
