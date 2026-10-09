import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 12,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 28, width: 160),
          SizedBox(height: 20),
          SkeletonLoader(height: 160, borderRadius: 24),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 20)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 20)),
            ],
          ),
          SizedBox(height: 24),
          SkeletonLoader(height: 20, width: 120),
          SizedBox(height: 12),
          SkeletonLoader(height: 72, borderRadius: 16),
          SizedBox(height: 10),
          SkeletonLoader(height: 72, borderRadius: 16),
          SizedBox(height: 10),
          SkeletonLoader(height: 72, borderRadius: 16),
        ],
      ),
    );
  }
}
