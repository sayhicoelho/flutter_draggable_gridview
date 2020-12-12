import 'package:flutter/material.dart';

class Moveable extends StatefulWidget {
  final double x;
  final double y;
  final Widget child;
  final void Function(Offset, Offset) onDrag;
  final void Function() onDrop;

  const Moveable({
    Key key,
    @required this.child,
    @required this.x,
    @required this.y,
    this.onDrag,
    this.onDrop
  }) : super(key: key);

  @override
  _MoveableState createState() => _MoveableState();
}

class _MoveableState extends State<Moveable> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: widget.x,
      top: widget.y,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onPanEnd: (details) {
          widget.onDrop?.call();
        },
        onPanUpdate: (details) {
          widget.onDrag?.call(
            details.delta,
            details.globalPosition
          );
        },
        child: widget.child,
      ),
    );
  }
}
