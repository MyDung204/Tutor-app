import 'dart:async';
import 'package:flutter/material.dart';

/// Một widget chữ chạy ngang (Marquee) mượt mà không cần thư viện ngoài.
/// Tự động cuộn và lặp lại dữ liệu khi độ dài chữ vượt quá không gian cho phép.
class EduMarquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity; // Tốc độ (pixels per second)
  final double gap; // Khoảng cách giữa các vòng lặp
  final Duration startDelay; // Thời gian chờ trước khi bắt đầu cuộn

  const EduMarquee({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 30.0,
    this.gap = 50.0,
    this.startDelay = const Duration(seconds: 2),
  });

  @override
  State<EduMarquee> createState() => _EduMarqueeState();
}

class _EduMarqueeState extends State<EduMarquee> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _shouldScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNeedsScrolling());
  }

  void _checkNeedsScrolling() async {
    if (!mounted) return;
    
    // Kiểm tra xem chữ có bị tràn hay không
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.maxScrollExtent > 0) {
        setState(() {
          _shouldScroll = true;
        });
        await Future.delayed(widget.startDelay);
        _startScrolling();
      }
    }
  }

  void _startScrolling() {
    if (!mounted) return;
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_scrollController.hasClients) {
        double newOffset = _scrollController.offset + (widget.velocity * 0.05); // 0.05s = 50ms
        
        if (newOffset >= _scrollController.position.maxScrollExtent) {
          // Khi cuộn hết, quay lại đầu (nếu muốn hiệu ứng lặp vô hạn thì cần duplicate widget trong Row)
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(newOffset);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldScroll) {
       return Text(widget.text, style: widget.style, overflow: TextOverflow.ellipsis, maxLines: 1);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.text, style: widget.style),
          SizedBox(width: widget.gap),
          Text(widget.text, style: widget.style), // Duplicate to create loop effect
          SizedBox(width: widget.gap),
        ],
      ),
    );
  }
}
