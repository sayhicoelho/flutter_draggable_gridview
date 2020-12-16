import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Moveable extends StatefulWidget {
  final double x;
  final double y;
  final Widget child;
  final Widget feedback;
  final void Function() onDragStart;
  final void Function(Offset, Offset) onDragUpdate;
  final void Function() onDrop;

  const Moveable({
    Key key,
    @required this.child,
    @required this.feedback,
    @required this.x,
    @required this.y,
    this.onDragStart,
    this.onDragUpdate,
    this.onDrop
  }) : super(key: key);

  @override
  _MoveableState createState() => _MoveableState();
}

class _MoveableState extends State<Moveable> {
  Offset _lastGlobalPosition;
  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: widget.x,
      top: widget.y,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onLongPressMoveUpdate: (details) {
          if (_lastGlobalPosition == null) {
            _lastGlobalPosition = details.globalPosition;
          }

          widget.onDragUpdate?.call(
            Offset(
              details.globalPosition.dx - _lastGlobalPosition.dx,
              details.globalPosition.dy - _lastGlobalPosition.dy
            ),
            details.globalPosition
          );

          _lastGlobalPosition = details.globalPosition;
        },
        onLongPressStart: (details) {
          widget.onDragStart?.call();
          setState(() {
            _moving = true;
          });
        },
        onLongPressEnd: (details) {
          _lastGlobalPosition = null;
          widget.onDrop?.call();
          setState(() {
            _moving = false;
          });
        },
        child: _moving
          ? widget.feedback
          : widget.child
      ),
    );
  }
}
