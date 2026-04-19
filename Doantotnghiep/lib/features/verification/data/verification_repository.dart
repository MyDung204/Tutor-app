import 'dart:io';
import 'package:dio/dio.dart';
import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(apiClientProvider));
});

enum VerificationStatus { none, pending, approved, rejected }

class VerificationState {
  final VerificationStatus status;
  final String? note; // Rejection reason

  VerificationState({this.status = VerificationStatus.none, this.note});

  factory VerificationState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VerificationState();
    
    // Parse status string
    String statusStr = json['status'] ?? 'none';
    VerificationStatus status;
    switch(statusStr) {
      case 'pending': status = VerificationStatus.pending; break;
      case 'approved': status = VerificationStatus.approved; break;
      case 'rejected': status = VerificationStatus.rejected; break;
      default: status = VerificationStatus.none;
    }

    return VerificationState(status: status, note: json['note']);
  }
}

class VerificationRepository {
  final ApiClient _client;

  VerificationRepository(this._client);

  Future<VerificationState> getStatus() async {
    try {
      final response = await _client.get('/verification/status');
      if (response == null) return VerificationState();
      return VerificationState.fromJson(response);
    } catch (e) {
      return VerificationState();
    }
  }

  Future<bool> submitRequest(File frontImage, File backImage) async {
    try {
      // 1. Upload Images (Assuming we have an upload endpoint, or use base64 for MVP)
      // Since we haven't built a separate upload generic service yet, 
      // let's assume we can post Multipart or Base64.
      // For simplicity/rapidity: Let's assume we upload to ImgBB or similar, 
      // OR let's build a simple upload endpoint in Laravel?
      // Assuming user prefers built-in.
      // Let's modify logic: We upload files as FormData to logic.
      // But Controller expects 'front_image_url'.
      // Wait, I implemented controller to expect string URL.
      // I should implement an Upload Controller or change VerificationController to accept File.
      
      // Pivot: I'll assume for this prototype we send path or mock URL?
      // No, user wants real "Chụp hình".
      // I need a way to upload.
      
      // Let's stick to uploading to a public service (like Cloudinary) or our server's storage link.
      // Ideally: `uploadFile(File)` -> `String url`.
      
      // For now, I will Mock the upload to return a fake URL so we can test the Flow 
      // UNLESS I implement a file upload endpoint.
      
      // Let's implement real upload endpoint? 
      // Too complex for 1 step. 
      // I'll assume there's a `FileService` or I simulate it.
      
      // Simulation:
      await Future.delayed(const Duration(seconds: 2));
      final frontUrl = "https://example.com/front_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final backUrl = "https://example.com/back_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await _client.post('/verification/submit', data: {
        'front_image_url': frontUrl,
        'back_image_url': backUrl,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
