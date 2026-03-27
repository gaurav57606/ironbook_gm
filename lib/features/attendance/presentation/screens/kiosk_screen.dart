import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/member_provider.dart';
import '../../../../data/local/models/member_snapshot_model.dart';

class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  String _pin = '';
  String _status = 'idle'; // idle, verifying, success, error
  String _message = 'Enter PIN to Check-in';

  void _onKeyPress(String key) {
    if (_status != 'idle' && _status != 'error') return;
    
    setState(() {
      if (key == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        if (_status == 'error') {
          _status = 'idle';
          _message = 'Enter PIN to Check-in';
        }
      } else if (_pin.length < 4) {
        _pin += key;
        if (_status == 'error') {
          _status = 'idle';
          _message = 'Enter PIN to Check-in';
        }
        if (_pin.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  void _verifyPin() {
    setState(() {
      _status = 'verifying';
      _message = 'Verifying...';
    });
    
    // Safety delay for UX
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      final members = ref.read(membersProvider);
      
      // Find member by PIN or last 4 digits of phone
      final foundMember = members.where((m) {
        if (m.checkInPin == _pin) return true;
        if (m.phone != null && m.phone!.length >= 4) {
          return m.phone!.substring(m.phone!.length - 4) == _pin;
        }
        return false;
      }).firstOrNull;

      if (foundMember != null) {
        final status = foundMember.getStatus(DateTime.now());
        if (status == MemberStatus.expired) {
          setState(() {
            _status = 'error';
            _message = 'Plan Expired for ${foundMember.name}';
          });
          Future.delayed(const Duration(seconds: 4), _reset);
        } else {
          setState(() {
            _status = 'success';
            _message = 'Welcome, ${foundMember.name}!';
          });
          
          ref.read(membersProvider.notifier).recordAttendance(foundMember.memberId);
          
          Future.delayed(const Duration(seconds: 4), _reset);
        }
      } else {
        setState(() {
          _status = 'error';
          _message = 'Member Not Found';
        });
        Future.delayed(const Duration(seconds: 3), _reset);
      }
    });
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _pin = '';
      _status = 'idle';
      _message = 'Enter PIN to Check-in';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StatusBarWrapper(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 60),
                _buildStatusIndicator(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _status == 'error' ? AppColors.red : AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildPinDisplay(),
                const Spacer(),
                _buildKeypad(),
                const SizedBox(height: 40),
              ],
            ),
            Positioned(
              top: 10,
              right: 14,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: AppColors.text3, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color = AppColors.bg3;
    IconData icon = Icons.timer_outlined;
    
    if (_status == 'success') {
      color = AppColors.green;
      icon = Icons.check_circle_outline;
    } else if (_status == 'error') {
      color = AppColors.red;
      icon = Icons.error_outline;
    } else if (_status == 'verifying') {
      color = AppColors.orange;
      icon = Icons.sync;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: _status == 'verifying' 
          ? const CircularProgressIndicator(color: AppColors.orange, strokeWidth: 3)
          : Icon(icon, color: color, size: 48),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool filled = _pin.length > index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: filled ? AppColors.orange : AppColors.bg3,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((k) => _buildKey(k)),
          const SizedBox(),
          _buildKey('0'),
          _buildKey('⌫'),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg3.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            key,
            style: TextStyle(
              fontSize: key == '⌫' ? 14 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
