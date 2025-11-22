import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/common/offline_indicator.dart';
import '../providers/offline_provider.dart';

/// Wrapper للتطبيق يضيف مؤشر الأوف لاين والمزامنة التلقائية
class AppWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // بدء المزامنة التلقائية
    Future.microtask(() {
      ref.read(syncServiceProvider).startAutoSync();
    });
  }

  @override
  void dispose() {
    ref.read(syncServiceProvider).stopAutoSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineIndicator(),
        Expanded(child: widget.child),
      ],
    );
  }
}
