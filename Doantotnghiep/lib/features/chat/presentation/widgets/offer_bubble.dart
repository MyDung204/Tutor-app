import 'package:doantotnghiep/features/chat/domain/models/course_offer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfferBubble extends StatelessWidget {
  final CourseOffer offer;
  final bool isUser; // If true, current user SENT this offer.
  final Function(String status)? onStatusUpdate;

  const OfferBubble({
    super.key, 
    required this.offer, 
    required this.isUser,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getHeaderColor(offer.status),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                 Icon(_getHeaderIcon(offer.status), color: _getTextColor(offer.status), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đề xuất khóa học',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(offer.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.subject,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.calendar_today, offer.schedule),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.refresh, '${offer.sessionsPerWeek} buổi/tuần'),
                const SizedBox(height: 8),
                Text(
                  '${currencyFormat.format(offer.price)}/buổi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                
                // ACTION AREA
                if (offer.status == 'pending') ...[
                  if (!isUser) ...[
                    // Receiver actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onStatusUpdate?.call('accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                         onPressed: () => onStatusUpdate?.call('rejected'),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.grey,
                           side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         ),
                         child: const Text('Từ chối'),
                      ),
                    ),
                  ] else ...[
                     // Sender waiting
                     Center(
                      child: Text(
                        'Đang chờ phản hồi...',
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]
                ] else ...[
                  // Final Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(offer.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(offer.status).withOpacity(0.5)),
                    ),
                    child: Text(
                      offer.status == 'accepted' 
                          ? 'Đã chấp nhận' 
                          : 'Đã từ chối',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getStatusColor(offer.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }

  Color _getHeaderColor(String status) {
    switch (status) {
      case 'accepted': return Colors.green.withOpacity(0.1);
      case 'rejected': return Colors.red.withOpacity(0.1);
      default: return Colors.orange.withOpacity(0.1);
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange[800]!;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getHeaderIcon(String status) {
     switch (status) {
      case 'accepted': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.verified_user;
    }
  }
}
