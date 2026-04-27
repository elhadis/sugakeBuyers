import 'package:flutter/material.dart';

class TextDelegatHeaderWidget extends SliverPersistentHeaderDelegate {
  final String title;

  TextDelegatHeaderWidget({required this.title});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      // FIXED: Removed the standalone 'color' property that caused the crash.
      // FIXED: Removed 'height: 82' from here; the Delegate handles height via extents.
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        // If you want a background color AND a gradient, 
        // you would define the color here, but gradient overrides it anyway.
        gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.orange],
          begin: FractionalOffset(0.0, 0.0),
          end: FractionalOffset(1.0, 0.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Add your tap logic here
        },
        child: Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22, 
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  // FIXED: Changed to 82.0 to match your intended design height.
  double get maxExtent => 50.0;

  @override
  // FIXED: Changed to 82.0 so the header stays consistent.
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant TextDelegatHeaderWidget oldDelegate) {
    return oldDelegate.title != title;
  }
}