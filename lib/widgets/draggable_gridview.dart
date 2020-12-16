import 'package:flutter/material.dart';
import 'package:flutter_draggable_gridview/widgets/moveable.dart';

class DraggableGridView<T> extends StatefulWidget {
  final int crossAxisCount;
  final List<DraggableGridViewItem<T>> items;
  final Widget Function(BuildContext, int, DraggableGridViewItem<T>) builder;
  final void Function() onDragStart;
  final void Function() onDragStop;
  final void Function() onSort;

  const DraggableGridView({
    Key key,
    @required this.crossAxisCount,
    @required this.items,
    @required this.builder,
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
                items: widget.items,
                builder: widget.builder,
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
  final void Function() onDragStart;
  final void Function() onDragStop;
  final void Function(int) onSort;

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
    @required this.onDragStart,
    @required this.onDragStop,
    @required this.onSort,
  }) : super(key: key);

  @override
  _DraggableGridViewTileState<T> createState() => _DraggableGridViewTileState<T>();
}

class _DraggableGridViewTileState<T> extends State<DraggableGridViewTile<T>> with WidgetsBindingObserver {
  bool _dragging = false;
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

  void _handleTarget(Offset globalPosition) {
    Offset gridOffset = _getGridOffset();
    double x = globalPosition.dx - gridOffset.dx;
    double y = globalPosition.dy - gridOffset.dy;

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

        _handleTarget(globalPosition);
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
                child: widget.builder(context, widget.index, widget.items[widget.index]),
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
