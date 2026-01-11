import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class GlobalInteractionObserver extends StatefulWidget {
  final Widget child;

  const GlobalInteractionObserver({super.key, required this.child});

  @override
  State<GlobalInteractionObserver> createState() =>
      _GlobalInteractionObserverState();
}

class _GlobalInteractionObserverState extends State<GlobalInteractionObserver> {
  DateTime? _lastScrollLogTime;

  void _logTap(PointerDownEvent event) {
    // Determine screen context from AnalyticsService
    final currentScreen = AnalyticsService().currentScreenName;
    AnalyticsService().logTap(
      screenName: currentScreen,
      x: event.position.dx,
      y: event.position.dy,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      if (_lastScrollLogTime == null ||
          now.difference(_lastScrollLogTime!) > const Duration(seconds: 2)) {
        _lastScrollLogTime = now;

        final currentScreen = AnalyticsService().currentScreenName;
        // Determine approximate direction (simplified)
        // Ideally we'd compare metrics.pixels, but for "didik didik" just knowing they scrolled is good start.
        // Or we can track delta.
        String direction = 'vertical'; // Default for list views
        if (notification.metrics.axis == Axis.horizontal) {
          direction = 'horizontal';
        }

        AnalyticsService().logScroll(
          screenName: currentScreen,
          direction: direction,
        );
      }
    }
    return false; // Allow bubbling
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _logTap,
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    );
  }
}
