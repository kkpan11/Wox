import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wox/entity/wox_list_item.dart';
import 'package:wox/enums/wox_direction_enum.dart';
import 'package:wox/utils/log.dart';
import 'package:wox/utils/wox_theme_util.dart';

class WoxListController<T> extends GetxController {
  final RxList<WoxListItem<T>> _originalItems = <WoxListItem<T>>[].obs; // original items for filter and restore
  final RxList<WoxListItem<T>> _items = <WoxListItem<T>>[].obs;

  final RxInt _activeIndex = 0.obs;
  final RxInt _hoveredIndex = (-1).obs;

  final Function(WoxListItem item)? onItemExecuted;
  final Function(WoxListItem item)? onItemActive;
  final Function()? onFilterEscPressed;

  /// This flag is used to control whether the item is selected by mouse hover.
  /// This is used to prevent the item from being selected when the mouse is just hovering over the item in the result list.
  var isMouseMoved = false;

  final ScrollController scrollController = ScrollController();
  final FocusNode filterBoxFocusNode = FocusNode();
  final TextEditingController filterBoxController = TextEditingController();

  WoxListController({
    this.onItemExecuted,
    this.onItemActive,
    this.onFilterEscPressed,
  });

  RxList<WoxListItem<T>> get items => _items;

  RxInt get hoveredIndex => _hoveredIndex;

  RxInt get activeIndex => _activeIndex;

  WoxListItem<T> get activeItem => _items[_activeIndex.value];

  void updateActiveIndexByDirection(String traceId, WoxDirection direction) {
    Logger.instance.debug(traceId, "updateActiveIndex start, direction: $direction, activeIndex: ${_activeIndex.value}");

    if (_items.isEmpty) {
      Logger.instance.debug(traceId, "updateActiveIndex: items list is empty");
      return;
    }

    var newIndex = _activeIndex.value;
    if (direction == WoxDirectionEnum.WOX_DIRECTION_DOWN.code) {
      newIndex++;
      if (newIndex >= _items.length) {
        newIndex = 0;
      }

      int safetyCounter = 0;
      while (newIndex < _items.length && _items[newIndex].isGroup && safetyCounter < _items.length) {
        newIndex++;
        safetyCounter++;
        if (newIndex >= _items.length) {
          newIndex = 0;
          break;
        }
      }
    }

    if (direction == WoxDirectionEnum.WOX_DIRECTION_UP.code) {
      newIndex--;
      if (newIndex < 0) {
        newIndex = _items.length - 1;
      }

      int safetyCounter = 0;
      while (newIndex >= 0 && _items[newIndex].isGroup && safetyCounter < _items.length) {
        newIndex--;
        safetyCounter++;
        if (newIndex < 0) {
          newIndex = _items.length - 1;
          break;
        }
      }
    }

    updateActiveIndex(traceId, newIndex);
  }

  void updateActiveIndex(String traceId, int index) {
    _activeIndex.value = index;
    _syncScrollPositionWithActiveIndex(traceId);

    onItemActive?.call(_items[index]);

    Logger.instance.debug(traceId, "updateActiveIndex end, new activeIndex: ${_activeIndex.value}");
  }

  void _syncScrollPositionWithActiveIndex(String traceId) {
    Logger.instance.debug(traceId, "changeScrollPosition, activeIndex: ${_activeIndex.value}");

    if (!scrollController.hasClients) {
      Logger.instance.debug(traceId, "ScrollController not attached to any scroll views yet");
      return;
    }

    if (_items.length <= WoxThemeUtil.instance.getMaxResultCount()) {
      return;
    }

    final itemHeight = WoxThemeUtil.instance.getResultItemHeight();
    final maxResultCount = WoxThemeUtil.instance.getMaxResultCount();

    // Calculate the range of currently visible items
    final currentOffset = scrollController.offset;
    final firstVisibleItemIndex = (currentOffset / itemHeight).floor();
    final lastVisibleItemIndex = firstVisibleItemIndex + maxResultCount - 1;

    Logger.instance.debug(traceId, "Visible range: $firstVisibleItemIndex - $lastVisibleItemIndex, active: ${_activeIndex.value}");

    // If the active item is already in the visible range, no need to scroll
    if (_activeIndex.value >= firstVisibleItemIndex && _activeIndex.value <= lastVisibleItemIndex) {
      return;
    }

    // If the active item is before the visible range, scroll up to make it visible
    if (_activeIndex.value < firstVisibleItemIndex) {
      // Scroll the active item to the top of the visible area
      final newOffset = _activeIndex.value * itemHeight;
      scrollController.jumpTo(newOffset);
      return;
    }

    // If the active item is after the visible range, scroll down to make it visible
    if (_activeIndex.value > lastVisibleItemIndex) {
      // Scroll the active item to the bottom of the visible area
      final newOffset = (_activeIndex.value - maxResultCount + 1) * itemHeight;
      scrollController.jumpTo(newOffset);
      return;
    }
  }

  void updateItem(String traceId, WoxListItem<T> item) {
    Logger.instance.debug(traceId, "updateItem, item: $item");

    // update original items
    final originalIndex = _originalItems.indexWhere((element) => element.id == item.id);
    if (originalIndex != -1) {
      _originalItems[originalIndex] = item;
    }

    // update items
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  void updateHoveredIndex(int index) {
    _hoveredIndex.value = index;
  }

  void clearHoveredResult() {
    _hoveredIndex.value = -1;
  }

  void updateItems(String traceId, List<WoxListItem<T>> newItems) {
    _items.value = newItems;

    if (_activeIndex.value >= _items.length && _items.isNotEmpty) {
      updateActiveIndex(traceId, 0);
    }
    Logger.instance.debug(traceId, "setItems end, items: ${_items.length}");
  }

  bool isItemActive(String itemId) {
    final index = _items.indexWhere((element) => element.id == itemId);
    return index != -1 && index == _activeIndex.value;
  }

  void requestFocus() {
    filterBoxFocusNode.requestFocus();
  }

  void filterItems(String traceId, String filterText) {
    _items.assignAll(_originalItems.where((element) => element.title.contains(filterText)).toList());
    if (_items.isNotEmpty) {
      updateActiveIndex(traceId, 0);
    }
  }

  void clearItems() {
    _items.clear();
    _originalItems.clear();
    _activeIndex.value = 0;
    _hoveredIndex.value = -1;
  }

  @override
  void onClose() {
    super.onClose();

    scrollController.dispose();
  }
}
