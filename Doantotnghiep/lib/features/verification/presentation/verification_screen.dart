import 'dart:io';
import 'package:doantotnghiep/features/verification/data/verification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  File? _frontImage;
  File? _backImage;
  bool _isLoading = false;
  VerificationState? _currentState;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final status = await ref.read(verificationRepositoryProvider).getStatus();
    setState(() {
      _currentState = status;
      _isLoading = false;
    });
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery); // Can change to camera
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null || _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp cả 2 mặt giấy tờ.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(verificationRepositoryProvider).submitRequest(
      _frontImage!,
      _backImage!,
    );
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi yêu cầu thành công!')),
      );
      _loadStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi gửi yêu cầu. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Status View
    if (_currentState?.status == VerificationStatus.pending) {
      return Scaffold(
        appBar: AppBar(title: const Text('Xác thực tài khoản')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('Đang chờ duyệt hồ sơ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Admin đang kiểm tra thông tin của bạn.\nVui lòng quay lại sau.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: _loadStatus, child: const Text('Làm mới trạng thái')),
            ],
          ),
        ),
      );
    }
    
    if (_currentState?.status == VerificationStatus.approved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Xác thực tài khoản')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Đã xác thực', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tài khoản của bạn đã được xác minh.\nBạn đã được đánh dấu tích xanh uy tín!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Submission Form (Includes 'rejected' state to allow retry)
    return Scaffold(
      appBar: AppBar(title: const Text('Nộp hồ sơ xác thực')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentState?.status == VerificationStatus.rejected)
               Container(
                 padding: const EdgeInsets.all(12),
                 margin: const EdgeInsets.only(bottom: 16),
                 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                 child: Row(
                   children: [
                     const Icon(Icons.error_outline, color: Colors.red),
                     const SizedBox(width: 8),
                     Expanded(child: Text("Hồ sơ bị từ chối: ${_currentState?.note ?? ''}", style: const TextStyle(color: Colors.red))),
                   ],
                 ),
               ),
            
            const Text(
              'Vui lòng tải lên hình ảnh Thẻ Căn Cước/Thẻ Ngành (2 mặt) để xác minh danh tính.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Front Image
            _buildImagePicker('Mặt trước', _frontImage, () => _pickImage(true)),
            const SizedBox(height: 16),
            // Back Image
            _buildImagePicker('Mặt sau', _backImage, () => _pickImage(false)),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Gửi hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
              image: image != null 
                ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) 
                : null,
            ),
            child: image == null 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chạm để chụp/tải ảnh'),
                  ],
                )
              : null,
          ),
        ),
      ],
    );
  }
}
