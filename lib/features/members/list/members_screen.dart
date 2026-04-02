import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/member_provider.dart';
import '../../../data/local/models/member_snapshot_model.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allMembers = ref.watch(membersProvider);
    final members = _searchQuery.isEmpty 
        ? allMembers 
        : allMembers.where((m) => 
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            (m.phone != null && m.phone!.contains(_searchQuery))).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Members', style: AppTextStyles.cardTitle),
        backgroundColor: AppColors.bg,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: members.isEmpty 
          ? Center(child: Text(_searchQuery.isEmpty ? 'No members yet.' : 'No matches found.', style: AppTextStyles.bodySmall))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildMemberTile(context, members[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, MemberSnapshot member) {
    final name = member.name;
    final isExpired = member.status == MemberStatus.expired;
    final isExpiring = member.status == MemberStatus.expiring;
    
    final statusColor = isExpired ? AppColors.expired : (isExpiring ? AppColors.expiring : AppColors.active);

    return InkWell(
      onTap: () => context.push('/members/${member.memberId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bg4, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.bg4,
              child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(member.phone ?? 'No phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.status.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
