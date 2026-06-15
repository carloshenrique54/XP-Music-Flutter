import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E0535),
      highlightColor: const Color(0xFF3D0D6B),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E0535),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SongSkeletonCard extends StatelessWidget {
  const SongSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF140826),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 60, height: 60, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 14),
                const SizedBox(height: 8),
                SkeletonLoader(width: MediaQuery.of(context).size.width * 0.35, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonLoader(width: 36, height: 36, radius: 18),
        ],
      ),
    );
  }
}

class PlaylistSkeletonCard extends StatelessWidget {
  const PlaylistSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 150, height: 150, radius: 16),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 120, height: 12),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 80, height: 10),
        ],
      ),
    );
  }
}
