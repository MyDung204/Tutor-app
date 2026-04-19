import 'package:flutter/material.dart';

/// Empty state widget for better UX
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for search results
class SearchEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const SearchEmptyState({
    super.key,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Không tìm thấy kết quả',
      message: 'Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm của bạn.',
      action: onClearFilters != null
          ? ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Xóa bộ lọc'),
            )
          : null,
    );
  }
}






