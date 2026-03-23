import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/member_provider.dart';
import '../../../data/local/models/plan_model.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPlanId;
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = _selectedDate.toIso8601String().split('T')[0];
    _loadPlans();
  }

  void _loadPlans() {
    final box = Hive.box<Plan>('plans');
    setState(() {
      _plans = box.values.toList();
      if (_plans.isNotEmpty) {
        _selectedPlanId = _plans.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member Info', style: AppTextStyles.cardTitle),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Rajesh Kumar'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+91 00000 00000'),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.length < 10 ? 'Invalid phone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Joining Date',
                  hintText: 'Select Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _dateController.text = date.toIso8601String().split('T')[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              Text('Plan Details', style: AppTextStyles.cardTitle),
              const SizedBox(height: 16),
              if (_plans.isEmpty)
                const Text('No plans available. Please seed data or add plans.')
              else
                DropdownButtonFormField<String>(
                  value: _selectedPlanId,
                  decoration: const InputDecoration(labelText: 'Select Plan'),
                  items: _plans.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} - ₹${p.totalPrice.toStringAsFixed(0)}'),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedPlanId = val!),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedPlanId != null) {
                      await ref.read(membersProvider.notifier).addMember(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        planId: _selectedPlanId!,
                        joinDate: _selectedDate,
                      );
                      if (mounted) context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Member & Collect Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
