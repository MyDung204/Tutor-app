import 'package:flutter/material.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Tin tức & Kinh nghiệm'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: blogPosts.length,
        itemBuilder: (context, index) {
          final post = blogPosts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    post.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EduTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(
                            color: EduTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.excerpt,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(post.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Đọc tiếp'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BlogPost {
  final String title;
  final String excerpt;
  final String date;
  final String category;
  final String imageUrl;

  const BlogPost({
    required this.title,
    required this.excerpt,
    required this.date,
    required this.category,
    required this.imageUrl,
  });
}

final blogPosts = [
  const BlogPost(
    title: '5 Bí quyết giúp Gia sư lấy lòng học viên trong buổi đầu',
    excerpt: 'Ấn tượng đầu tiên là cực kỳ quan trọng. Làm sao để học viên tin tưởng và muốn học cùng bạn lâu dài...',
    date: '05/01/2026',
    category: 'KINH NGHIỆM',
    imageUrl: 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=500',
  ),
  const BlogPost(
    title: 'Cập nhật quy chế thi THPT Quốc gia 2026 mới nhất',
    excerpt: 'Bộ Giáo dục vừa công bố dự thảo phương án thi tốt nghiệp THPT từ năm 2026 với nhiều thay đổi đáng chú ý...',
    date: '02/01/2026',
    category: 'TIN TỨC',
    imageUrl: 'https://images.unsplash.com/photo-1543269865-cbf427effbad?w=500',
  ),
  const BlogPost(
    title: 'Cách soạn giáo án Online cực nhanh với Canval và AI',
    excerpt: 'Công nghệ đang giúp việc giảng dạy trở nên dễ dàng hơn bao giờ hết. Hãy khám phá bộ công cụ soạn bài...',
    date: '30/12/2025',
    category: 'CÔNG NGHỆ',
    imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=500',
  ),
];
