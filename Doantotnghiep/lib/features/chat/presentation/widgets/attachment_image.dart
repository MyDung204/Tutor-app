import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AttachmentImage extends StatefulWidget {
  final String url;
  const AttachmentImage({super.key, required this.url});

  @override
  State<AttachmentImage> createState() => _AttachmentImageState();
}

class _AttachmentImageState extends State<AttachmentImage> {
  int _retryAttempt = 0;

  @override
  Widget build(BuildContext context) {
    // Append timestamp to force fresh load on retry
    final effectiveUrl = _retryAttempt == 0 
        ? widget.url 
        : "${widget.url}?retry=$_retryAttempt";

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: widget.url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: effectiveUrl,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) {
                return Container(
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.grey),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _retryAttempt++;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
              fit: BoxFit.cover,
            )
          : Image.file(File(widget.url), fit: BoxFit.cover),
    );
  }
}
