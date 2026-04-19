import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const VideoCallScreen({super.key, required this.bookingId});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isJoining = false;
  final _jitsiMeetPlugin = JitsiMeet();

  @override
  void initState() {
    super.initState();
    // Auto join on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinMeeting();
    });
  }

  Future<void> _joinMeeting() async {
    setState(() => _isJoining = true);
    
    final user = ref.read(authRepositoryProvider).currentUser;
    final roomName = "Doantotnghiep_Booking_${widget.bookingId}";
    final displayName = user?.name ?? "User";
    final email = user?.email ?? "";
    final avatar = user?.avatarUrl;

    var options = JitsiMeetConferenceOptions(
      room: roomName,
      serverURL: "https://meet.jit.si", 
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
        email: email,
        avatar: avatar
      ),
      featureFlags: {
        "welcomepage.enabled": false,
        "resolution": "md", 
      },
    );

    try {
      await _jitsiMeetPlugin.join(options);
    } catch (error) {
      debugPrint("Jitsi Meet Error: $error");
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi kết nối: $error"), backgroundColor: Colors.red),
        );
         context.pop(); // Pop on error
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isJoining
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Đang kết nối đến phòng học...", style: TextStyle(color: Colors.white)),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("Cuộc gọi đã kết thúc hoặc đang chạy.", style: TextStyle(color: Colors.white70)),
                   SizedBox(height: 20),
                   // Back button
                ],
              ),
      ),
      floatingActionButton: !_isJoining ? FloatingActionButton(
        onPressed: () => context.pop(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.arrow_back),
      ) : null,
    );
  }
}
