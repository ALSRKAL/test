import 'package:flutter/material.dart';

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Axis direction;

  const StaggeredList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 50),
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            children: _buildStaggeredChildren(),
          )
        : Row(
            children: _buildStaggeredChildren(),
          );
  }

  List<Widget> _buildStaggeredChildren() {
    return List.generate(
      children.length,
      (index) => StaggeredListItem(
        delay: delay * index,
        child: children[index],
      ),
    );
  }
}

class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
