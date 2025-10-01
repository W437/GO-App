import 'package:flutter/material.dart';

class StoryProgressBarWidget extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final double progress;

  const StoryProgressBarWidget({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(itemCount, (index) {
        return Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: index == currentIndex
                  ? progress
                  : (index < currentIndex ? 1.0 : 0.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}