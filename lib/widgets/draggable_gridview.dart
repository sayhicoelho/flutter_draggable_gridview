import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_draggable_gridview/widgets/moveable.dart';

class DraggableGridView<T> extends StatefulWidget {
  final int crossAxisCount;
  final List<DraggableGridViewItem<T>> items;
  final Widget Function(BuildContext, int, DraggableGridViewItem<T>) builder;
  final Widget Function(BuildContext, int, DraggableGridViewItem<T>) feedback;
  final void Function() onDragStart;
  final void Function() onDragStop;
  final void Function() onSort;
  final ScrollController scrollController;

  const DraggableGridView({
    Key key,
    @required this.crossAxisCount,
    @required this.items,
    @required this.builder,
    @required this.scrollController,
    this.feedback,
    this.onDragStart,
    this.onDragStop,
    this.onSort,
  }) : super(key: key);

  @override
  _DraggableGridViewState<T> createState() => _DraggableGridViewState<T>();
}

class _DraggableGridViewState<T> extends State<DraggableGridView<T>> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var gridWidth = constraints.maxWidth;
        var tileWidth = gridWidth / widget.crossAxisCount;
        var gridHeight = tileWidth * (widget.items.length / widget.crossAxisCount).ceil();

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxHeight: gridHeight,
          ),
          child: Stack(
            overflow: Overflow.visible,
            children: [
              for (int i = 0; i < widget.items.length; i++) DraggableGridViewTile<T>(
                index: i,
                width: tileWidth,
                gridWidth: gridWidth,
                gridHeight: gridHeight,
                crossAxisCount: widget.crossAxisCount,
                scrollController: widget.scrollController,
                items: widget.items,
                builder: widget.builder,
                feedback: widget.feedback,
                context: context,
                onDragStart: widget.onDragStart,
                onDragStop: widget.onDragStop,
                onSort: (targetIndex) {
                  int oldOrder = widget.items[i].order;
                  bool isForward = widget.items[i].order < widget.items[targetIndex].order;
                  int targetOrder = widget.items[targetIndex].order;

                  if (isForward) {
                    for (int order = oldOrder + 1; order <= targetOrder; order++) {
                      var slaveIndex = widget.items.indexWhere((item) => item.order == order);
                      widget.items[slaveIndex].order--;
                      widget.items[slaveIndex].x = tileWidth * ((widget.items[slaveIndex].order - 1) % widget.crossAxisCount);
                      widget.items[slaveIndex].y = tileWidth * (((widget.items[slaveIndex].order - 1) / widget.crossAxisCount) % widget.items.length).floor();
                    }
                  } else {
                    for (int order = oldOrder - 1; order >= targetOrder; order--) {
                      var slaveIndex = widget.items.indexWhere((item) => item.order == order);
                      widget.items[slaveIndex].order++;
                      widget.items[slaveIndex].x = tileWidth * ((widget.items[slaveIndex].order - 1) % widget.crossAxisCount);
                      widget.items[slaveIndex].y = tileWidth * (((widget.items[slaveIndex].order - 1) / widget.crossAxisCount) % widget.items.length).floor();
                    }
                  }

                  widget.items[i].order = targetOrder;
                  widget.onSort?.call();
                  setState(() {});
                }
              )
            ],
          ),
        );
      },
    );
  }
}

class DraggableGridViewTile<T> extends StatefulWidget {
  final int index;
  final double width;
  final BuildContext context;
  final double gridWidth;
  final double gridHeight;
  final int crossAxisCount;
  final List<DraggableGridViewItem<T>> items;
  final Widget Function(BuildContext, int, DraggableGridViewItem<T>) builder;
  final Widget Function(BuildContext, int, DraggableGridViewItem<T>) feedback;
  final void Function() onDragStart;
  final void Function() onDragStop;
  final void Function(int) onSort;
  final ScrollController scrollController;

  const DraggableGridViewTile({
    Key key,
    @required this.index,
    @required this.width,
    @required this.context,
    @required this.gridWidth,
    @required this.gridHeight,
    @required this.crossAxisCount,
    @required this.items,
    @required this.builder,
    @required this.scrollController,
    this.feedback,
    this.onDragStart,
    this.onDragStop,
    this.onSort,
  }) : super(key: key);

  @override
  _DraggableGridViewTileState<T> createState() => _DraggableGridViewTileState<T>();
}

class _DraggableGridViewTileState<T> extends State<DraggableGridViewTile<T>> with WidgetsBindingObserver {
  bool _dragging = false;
  bool _animatingScroll = false;
  OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setInitialTilePosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeMetrics() async {
    super.didChangeMetrics();
    await Future.delayed(Duration(milliseconds: 100));
    setState(_setInitialTilePosition);
  }

  void _setInitialTilePosition() {
    widget.items[widget.index].x = widget.width * ((widget.items[widget.index].order - 1) % widget.crossAxisCount);
    widget.items[widget.index].y = widget.width * (((widget.items[widget.index].order - 1) / widget.crossAxisCount) % widget.items.length).floor();
  }

  void _handleTarget(double x, double y) {
    var target = widget.items.firstWhere((item) {
      if (item.order != widget.items[widget.index].order
        && item.draggable) {
        if (x > item.x
          && x < (item.x + widget.width)
          && y > item.y
          && y < (item.y + widget.width)) {
            return true;
          }
      }

      return false;
    }, orElse: () => null);

    if (target != null) {
      var targetIndex = widget.items.indexWhere((item) => item.order == target.order);
      widget.onSort?.call(targetIndex);
    }
  }

  Offset _getGridOffset() {
    RenderBox box = widget.context.findRenderObject();
    return box.localToGlobal(Offset.zero);
  }

  void _animateScroll(double offset) {
    _animatingScroll = true;
    widget.scrollController.animateTo(
      offset,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut
    );
  }

  void _stopScrollAnimation() {
    _animatingScroll = false;
    widget.scrollController.animateTo(
      widget.scrollController.offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad
    );
  }

  @override
  Widget build(BuildContext context) {
    return Moveable(
      x: widget.items[widget.index].x,
      y: widget.items[widget.index].y,
      canMove: widget.items[widget.index].draggable,
      onDragUpdate: (delta, globalPosition) {
        setState(() {
          widget.items[widget.index].x += delta.dx;
          widget.items[widget.index].y += delta.dy;
          _overlayEntry.markNeedsBuild();
        });

        var gridOffset = _getGridOffset();
        var x = globalPosition.dx - gridOffset.dx;
        var y = globalPosition.dy - gridOffset.dy;
        var absoluteGridOffsetTop = widget.scrollController.offset + gridOffset.dy;
        var absoluteGridOffsetBottom = widget.gridHeight + absoluteGridOffsetTop;

        if (globalPosition.dy <= (kToolbarHeight + 100.0)
          && widget.scrollController.offset > gridOffset.dy
          && !_animatingScroll) {
          _animateScroll(absoluteGridOffsetTop - 100);
        } else if (globalPosition.dy >= (MediaQuery.of(context).size.height - 100.0)
          && (MediaQuery.of(context).size.height + widget.scrollController.offset) < (absoluteGridOffsetBottom)
          && !_animatingScroll) {
          _animateScroll((absoluteGridOffsetBottom - MediaQuery.of(context).size.height) + 20);
        } else if (globalPosition.dy > (kToolbarHeight + 100.0)
          && globalPosition.dy < (MediaQuery.of(context).size.height - 100.0)
          && _animatingScroll) {
          _stopScrollAnimation();
        }

        _handleTarget(x, y);
      },
      onDragStart: () {
        widget.onDragStart?.call();

        setState(() {
          _dragging = true;
        });

        Offset gridOffset = _getGridOffset();
        Overlay.of(context).insert(
          _overlayEntry = OverlayEntry(
            builder: (context) => TileOverlay(
              left: widget.items[widget.index].x + gridOffset.dx,
              top: widget.items[widget.index].y + gridOffset.dy,
              width: widget.width,
              child: Container(
                width: widget.width,
                height: widget.width,
                child: widget.feedback != null
                  ? widget.feedback(context, widget.index, widget.items[widget.index])
                  : widget.builder(context, widget.index, widget.items[widget.index]),
              )
            )
          )
        );
      },
      onDrop: () {
        widget.onDragStop?.call();
        setState(() {
          _setInitialTilePosition();
          _dragging = false;
        });
        _overlayEntry?.remove();
      },
      child: Visibility(
        visible: !_dragging,
        child: Container(
          width: widget.width,
          height: widget.width,
          child: widget.builder(context, widget.index, widget.items[widget.index]),
        ),
      ),
    );
  }
}

class TileOverlay extends StatefulWidget {
  final double left;
  final double top;
  final double width;
  final Widget child;

  const TileOverlay({
    Key key,
    @required this.left,
    @required this.top,
    @required this.width,
    @required this.child
  }) : super(key: key);

  @override
  _TileOverlayState createState() => _TileOverlayState();
}

class _TileOverlayState extends State<TileOverlay> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: widget.left,
      top: widget.top,
      width: widget.width,
      height: widget.width,
      child: Transform.scale(
        scale: 1.05,
        child: Opacity(
          opacity: .9,
          child: widget.child,
        )
      ),
    );
  }
}

class DraggableGridViewItem<T> {
  double x;
  double y;
  T data;
  int order;
  bool draggable;

  DraggableGridViewItem(this.data, this.order, {this.draggable = true});

  @override
  String toString() {
    return 'DraggableGridViewItem(x: $x, y: $y, data: $data, order: $order)';
  }
}
