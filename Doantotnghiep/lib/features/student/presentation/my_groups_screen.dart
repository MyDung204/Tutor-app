import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/group/data/group_request_provider.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhóm học tập'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nhóm của tôi'),
              Tab(text: 'Nhóm tham gia'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GroupList(provider: myCreatedGroupsProvider, isCreated: true),
            _GroupList(provider: myJoinedGroupsProvider, isCreated: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/create-group'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _GroupList extends ConsumerWidget {
  final Provider<AsyncValue<List<GroupRequest>>> provider;
  final bool isCreated;

  const _GroupList({required this.provider, required this.isCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(provider);

    return groupsAsync.when(
      skipLoadingOnRefresh: true,
      data: (groups) {
        if (groups.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myAllGroupsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isCreated ? Icons.group_add_outlined : Icons.group_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        isCreated ? 'Bạn chưa tạo nhóm nào' : 'Bạn chưa tham gia nhóm nào',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myAllGroupsProvider),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: InkWell(
                  onTap: () => context.push('/group-detail', extra: group),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                           children: [
                             Badge(
                               isLabelVisible: group.pendingRequestsCount > 0 || group.hasNewMessages,
                               label: group.pendingRequestsCount > 0 ? Text('${group.pendingRequestsCount}') : null,
                               smallSize: 10,
                               backgroundColor: Colors.red,
                               offset: const Offset(4, -4),
                               child: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                 child: const Icon(Icons.menu_book_outlined, color: Colors.blue),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(group.topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                   Text('${group.subject} - ${group.gradeLevel}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                 ],
                               ),
                             ),
                             if (group.membershipStatus == 'pending')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Chờ duyệt', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                             else if (group.status == 'open')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Đang tìm', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                             else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Đã đóng', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                           ],
                         ),
                         const Divider(height: 24),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             _InfoItem(icon: Icons.people_outline, text: '${group.currentMembers}/${group.maxMembers} Tv'),
                             _InfoItem(icon: Icons.attach_money, text: '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(group.pricePerSession)}'),
                             _InfoItem(icon: Icons.calendar_today, text: DateFormat('dd/MM').format(group.startTime)),
                           ],
                         )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
         Icon(icon, size: 16, color: Colors.grey[600]),
         const SizedBox(width: 4),
         Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
