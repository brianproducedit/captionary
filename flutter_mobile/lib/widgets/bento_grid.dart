import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BentoGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;

  const BentoGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return itemBuilder(context, index)
            .animate()
            .fade(duration: 400.ms, delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}
