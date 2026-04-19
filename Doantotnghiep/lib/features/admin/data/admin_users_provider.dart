import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';

final adminUsersProvider = FutureProvider.autoDispose.family<List<dynamic>, UserFilter>((ref, filter) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getUsers(
    search: filter.search,
    role: filter.role,
  );
});

class UserFilter {
  final String search;
  final String role;

  const UserFilter({this.search = '', this.role = 'All'});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserFilter && other.search == search && other.role == role;
  }

  @override
  int get hashCode => search.hashCode ^ role.hashCode;
}
