import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';
import 'package:ironbook_gm/features/nutrition/domain/utils/nutrition_calculator.dart';
import 'package:ironbook_gm/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:ironbook_gm/features/nutrition/data/models/meal_item_model.dart';
import 'package:ironbook_gm/shared/widgets/status_bar_wrapper.dart';

class MealLoggingScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MealLoggingScreen({super.key, required this.memberId});

  @override
  ConsumerState<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends ConsumerState<MealLoggingScreen> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController(text: '100');
  final TextEditingController _baseCalController = TextEditingController(text: '100');
  
  double _calculatedCalories = 100.0;

  @override
  void initState() {
    super.initState();
    _gramsController.addListener(_updateCalories);
    _baseCalController.addListener(_updateCalories);
  }

  void _updateCalories() {
    final grams = double.tryParse(_gramsController.text) ?? 0.0;
    final baseCal = double.tryParse(_baseCalController.text) ?? 0.0;
    
    setState(() {
      _calculatedCalories = NutritionCalculator.calculateScaled(baseCal, grams);
    });
  }

  @override
  void dispose() {
    _foodController.dispose();
    _gramsController.dispose();
    _baseCalController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (_foodController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter food name'))
      );
      return;
    }

    final meal = MealItem(
      id: const Uuid().v4(),
      memberId: widget.memberId,
      foodName: _foodController.text,
      grams: double.tryParse(_gramsController.text) ?? 0.0,
      calories: _calculatedCalories.toInt(),
      timestamp: DateTime.now(),
    );

    await ref.read(nutritionProvider(widget.memberId).notifier).logMeal(meal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('LOG MEAL', style: AppTextStyles.heroNumber.copyWith(fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard(),
              const SizedBox(height: 32),
              _buildSummaryCard(),
              const SizedBox(height: 48),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('FOOD NAME'),
          TextField(
            controller: _foodController,
            style: AppTextStyles.body.copyWith(color: Colors.white),
            decoration: _inputDecoration('e.g. Chicken Breast'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('PORTION (G)'),
                    TextField(
                      controller: _gramsController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      decoration: _inputDecoration('Grams'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('CAL / 100G'),
                    TextField(
                      controller: _baseCalController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      decoration: _inputDecoration('Kcal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Center(
      child: Column(
        children: [
          Text(
            'TOTAL ENERGY',
            style: AppTextStyles.sectionTitle.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.orange, Colors.orangeAccent],
            ).createShader(bounds),
            child: Text(
              '${_calculatedCalories.toInt()} KCAL',
              style: AppTextStyles.heroNumber.copyWith(fontSize: 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Portion: ${_gramsController.text}g',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _saveMeal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppColors.orange.withValues(alpha: 0.4),
        ),
        child: Text(
          'LOG MEAL',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
