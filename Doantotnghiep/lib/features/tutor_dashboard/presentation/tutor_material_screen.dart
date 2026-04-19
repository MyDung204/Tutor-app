import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class TutorMaterialScreen extends StatefulWidget {
  const TutorMaterialScreen({super.key});

  @override
  State<TutorMaterialScreen> createState() => _TutorMaterialScreenState();
}

class _TutorMaterialScreenState extends State<TutorMaterialScreen> {
  // Mock data for materials
  final List<Map<String, dynamic>> _materials = [
    {
      'name': 'Giao_trinh_Toan_10_Nang_cao.pdf',
      'type': 'PDF',
      'size': '2.4 MB',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'name': 'Bai_tap_on_tap_chuong_1.docx',
      'type': 'DOCX',
      'size': '850 KB',
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        // Simulate upload
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Close loading
          setState(() {
            _materials.insert(0, {
              'name': file.name,
              'type': file.extension?.toUpperCase() ?? 'FILE',
              'size': '${(file.size / 1024).toStringAsFixed(1)} KB',
              'date': DateTime.now(),
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải lên tài liệu thành công!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài liệu'),
      ),
      body: _materials.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Chưa có tài liệu nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Tải lên ngay'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _materials.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final material = _materials[index];
                return _buildMaterialCard(material);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        label: const Text('Thêm tài liệu'),
        icon: const Icon(Icons.add),
        backgroundColor: EduTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    IconData iconData;
    Color iconColor;

    switch (material['type']) {
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'DOCX':
      case 'DOC':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${material['size']} • ${DateFormat('dd/MM/yyyy').format(material['date'])}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              // Show options: Delete, Rename, etc.
            },
          ),
        ],
      ),
    );
  }
}
