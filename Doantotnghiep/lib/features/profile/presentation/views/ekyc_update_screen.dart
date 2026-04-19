import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/verification/data/verification_repository.dart';

class EkycUpdateScreen extends ConsumerStatefulWidget {
  final bool isTutor;

  const EkycUpdateScreen({super.key, this.isTutor = false});

  @override
  ConsumerState<EkycUpdateScreen> createState() => _EkycUpdateScreenState();
}

class _EkycUpdateScreenState extends ConsumerState<EkycUpdateScreen> {
  File? _idCardImage;
  File? _degreeImage;
  File? _certificateImage;
  File? _studentCardImage;

  final _picker = ImagePicker();
// ... (Skipping to the upload button part in the next block)

  Future<void> _pickImage(Function(File) onPicked) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Wrap(
            children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() => onPicked(File(pickedFile.path)));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() => onPicked(File(pickedFile.path)));
                  }
                } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực danh tính (eKYC)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isTutor
                          ? 'Vui lòng cung cấp CMND/CCCD và Bằng cấp để được duyệt hồ sơ dạy.'
                          : 'Vui lòng cung cấp Thẻ Học sinh/Sinh viên để xác thực tài khoản.',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (widget.isTutor) ...[
              _buildUploadSection(
                title: 'CMND / CCCD / Hộ chiếu',
                description: 'Chụp rõ 2 mặt giấy tờ tùy thân.',
                imageFile: _idCardImage,
                onUpload: () => _pickImage((f) => _idCardImage = f),
              ),
              const SizedBox(height: 24),
              _buildUploadSection(
                title: 'Bằng cấp chuyên môn',
                description: 'Bằng Đại học, Cao đẳng hoặc Thẻ Sinh viên (nếu đang đi học).',
                imageFile: _degreeImage,
                onUpload: () => _pickImage((f) => _degreeImage = f),
              ),
              const SizedBox(height: 24),
              _buildUploadSection(
                title: 'Chứng chỉ / Thành tựu (Tùy chọn)',
                description: 'IELTS, TOEIC, Giải thưởng HSG...',
                imageFile: _certificateImage,
                onUpload: () => _pickImage((f) => _certificateImage = f),
                isOptional: true,
              ),
            ] else ...[
              _buildUploadSection(
                title: 'Thẻ Học sinh / Sinh viên',
                description: 'Chụp rõ mặt trước thẻ để xác nhận trạng thái học viên.',
                imageFile: _studentCardImage,
                onUpload: () => _pickImage((f) => _studentCardImage = f),
              ),
            ],

            const SizedBox(height: 32),
            // SafeArea để tránh button bị che bởi navigation bar
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     if ((widget.isTutor && (_idCardImage == null || _degreeImage == null)) || 
                         (!widget.isTutor && _studentCardImage == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng tải lên đủ các giấy tờ bắt buộc.')),
                        );
                        return;
                     }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator()),
                    );

                    // 2. Call API
                    final repo = ref.read(verificationRepositoryProvider);
                    repo.submitRequest(
                      _idCardImage ?? _studentCardImage!,
                      _degreeImage ?? _studentCardImage!
                    ).then((success) {
                      if (mounted) {
                        Navigator.pop(context); // Pop Dialog
                        if (success) {
                           showDialog(
                             context: context, 
                             builder: (ctx) => AlertDialog(
                               title: const Text('Đã gửi yêu cầu'),
                               content: const Text('Hồ sơ của bạn đã được gửi. Vui lòng chờ Admin phê duyệt.'),
                               actions: [
                                 TextButton(onPressed: () {
                                   Navigator.pop(ctx);
                                   context.pop(); // Back to Profile
                                 }, child: const Text('Đồng ý'))
                               ],
                             )
                           );
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại.')),
                           );
                        }
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Gửi yêu cầu'),
                ),
              ),
            ),
            const SizedBox(height: 16), // Extra padding for navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String description,
    required File? imageFile,
    required VoidCallback onUpload,
    bool isOptional = false,
  }) {
    final isUploaded = imageFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isOptional)
              const Text(' (Tùy chọn)', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onUpload,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150, 
            width: double.infinity,
            decoration: BoxDecoration(
              color: isUploaded ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUploaded ? Colors.green : Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 1.5,
              ),
              image: isUploaded ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover, opacity: 0.8) : null
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                  size: 32,
                  color: isUploaded ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  isUploaded ? 'Đã chọn ảnh' : 'Bấm để chụp/tải ảnh',
                  style: TextStyle(
                    color: isUploaded ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
