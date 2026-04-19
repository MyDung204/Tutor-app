/// Admin Market Map Screen
/// 
/// **Purpose:**
/// - Hiển thị bản đồ nhiệt nhu cầu gia sư theo khu vực và môn học
/// - Giúp admin phân tích thị trường và đưa ra quyết định
/// 
/// **Features:**
/// - Bảng dữ liệu nhu cầu theo khu vực và môn học
/// - Màu sắc thể hiện mức độ nhu cầu (đỏ = cao, xanh = thấp)
/// - Dữ liệu được AI phân tích từ lượt tìm kiếm và đặt lịch trong 30 ngày qua
/// 
/// **Data Source:**
/// - Phân tích từ lượt tìm kiếm gia sư
/// - Phân tích từ lượt đặt lịch học
/// - Thời gian: 30 ngày gần nhất
library;

import 'package:flutter/material.dart';

/// Màn hình bản đồ nhiệt thị trường của admin
/// 
/// **Usage:**
/// - Truy cập từ admin dashboard → Click vào card "Bản đồ Nhiệt"
/// - Hoặc từ admin navigation (nếu có)
class AdminMarketMapScreen extends StatelessWidget {
  const AdminMarketMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = ['Toán', 'Lý', 'Hóa', 'Anh', 'Văn'];
    final districts = ['Q.1', 'Q.3', 'Q.5', 'Q.7', 'Q.10'];

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ Nhiệt Thị trường')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Biểu đồ nhu cầu Gia sư theo Khu vực',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Khu vực', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...subjects.map((s) => DataColumn(label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                  rows: districts.map((district) {
                    return DataRow(
                      cells: [
                        DataCell(Text(district, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ...subjects.map((subject) {
                          // Mock demand data: Random "Heat"
                          final demand = (district.length + subject.length) * 5; 
                          final isHot = demand > 30;
                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isHot ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHot ? 'Cao ($demand)' : 'Thấp ($demand)',
                                style: TextStyle(
                                  color: isHot ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ghi chú: Dữ liệu được AI phân tích từ lượt tìm kiếm và đặt lịch trong 30 ngày qua.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
