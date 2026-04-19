import 'package:flutter/material.dart';

/// Skeleton loading widget for better UX
class SkeletonLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton for tutor card
class TutorCardSkeleton extends StatelessWidget {
  const TutorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar skeleton
            SkeletonLoading(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(width: 16),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(width: double.infinity, height: 20),
                  const SizedBox(height: 8),
                  SkeletonLoading(width: 150, height: 16),
                  const SizedBox(height: 8),
                  SkeletonLoading(width: 100, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for list of tutor cards
class TutorListSkeleton extends StatelessWidget {
  final int itemCount;

  const TutorListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const TutorCardSkeleton(),
    );
  }
}






