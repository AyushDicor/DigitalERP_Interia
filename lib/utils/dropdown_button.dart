//  ErpDropdown<T>
//
//  A single, reusable dropdown that covers every use-case in the ERP app:
//    • Plain list        — isSearchable: false  (default)
//    • Searchable list   — isSearchable: true
//    • Loading state     — isLoading: true
//    • Disabled state    — enabled: false
//    • Error state       — hasError: true  (red border + "Required" pill)
//    • Optional leading icon on the button
//
//  Example — plain:
//  ──────────────────────────────────────────────────────
//  ErpDropdown<String>(
//    label: 'QC Required',
//    hint: 'Select…',
//    value: selected,
//    items: ['Yes', 'No'],
//    itemLabel: (s) => s,
//    onChanged: (v) => setState(() => selected = v),
//  )
//
//  Example — searchable with model:
//  ──────────────────────────────────────────────────────
//  ErpDropdown<MrnDropdownOption>(
//    label: 'Party Name',
//    hint: 'Search party…',
//    value: ctrl.selectedParty,
//    items: ctrl.partyList,
//    itemLabel: (o) => o.label,
//    isSearchable: true,
//    isLoading: ctrl.isLoadingParty,
//    hasError: ctrl.selectedParty == null,
//    onChanged: ctrl.setParty,
//  )
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

class ErpDropdown<T> extends StatefulWidget {
  const ErpDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.isLoading = false,
    this.isSearchable = false,
    this.hasError = false,
    this.enabled = true,
    this.prefixIcon,
    this.noItemsText = 'No options available',
  });

  final String label;
  final String hint;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final bool isLoading;
  final bool isSearchable;
  final bool hasError;
  final bool enabled;
  final IconData? prefixIcon;
  final String noItemsText;

  @override
  State<ErpDropdown<T>> createState() => _ErpDropdownState<T>();
}

class _ErpDropdownState<T> extends State<ErpDropdown<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get _showError => widget.hasError && widget.value == null;

  Color get _borderColor {
    if (!widget.enabled) return newBorderColor;
    if (_showError) return newRedColor;
    if (_isOpen) return newBlueColor;
    if (widget.value != null) return newBlueColor.withValues(alpha: 0.4);
    return newBorderColor;
  }

  double get _borderWidth {
    if (_showError || _isOpen) return 1.6;
    return 1.0;
  }

  Color get _fillColor {
    if (!widget.enabled) return newSurfaceColor.withValues(alpha: 0.6);
    if (widget.value != null) return Colors.white;
    return newSurfaceColor;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel(),
        const SizedBox(height: 5),
        if (widget.isLoading) const _Skeleton() else _buildButton(),
      ],
    );
  }

  // ── Label ──────────────────────────────────────────────────────────────────
  Widget _buildLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _showError ? newRedColor : newTextPrimary,
          ),
        ),
        if (_showError) ...[
          const SizedBox(width: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: newRedLightColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Required',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: newRedColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Button ─────────────────────────────────────────────────────────────────
  Widget _buildButton() {
    final hasValue = widget.value != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: _borderWidth),
        boxShadow: (_isOpen && widget.enabled)
            ? [
          BoxShadow(
            color: newBlueColor.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: DropdownButton2<T>(
        isExpanded: true,
        valueListenable: ValueNotifier(widget.value),
        onChanged: widget.enabled ? widget.onChanged : null,
        onMenuStateChange: (isOpen) {
          setState(() => _isOpen = isOpen);
          if (!isOpen) _searchCtrl.clear();
        },

        // ── Items ──────────────────────────────────────────────────────────
        items: widget.items.isEmpty
            ? [
          DropdownItem<T>(
            enabled: false,
            child: Text(
              widget.noItemsText,
              style: const TextStyle(
                fontSize: 12,
                color: newTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ]
            : widget.items.map((item) {
          final isSelected = item == widget.value;
          return DropdownItem<T>(
            value: item,
            child: _ItemRow(
              label: widget.itemLabel(item),
              isSelected: isSelected,
            ),
          );
        }).toList(),

        // ── Hint ─────────────────────────────────────────────────────────
        hint: _ButtonInner(
          text: widget.hint,
          isHint: true,
          prefixIcon: widget.prefixIcon,
        ),

        // ── Selected item display ─────────────────────────────────────────
        selectedItemBuilder: (_) => widget.items.map((item) {
          return _ButtonInner(
            text: widget.itemLabel(item),
            isHint: false,
            prefixIcon: widget.prefixIcon,
          );
        }),

        // ── Button chrome ─────────────────────────────────────────────────
        // ── Button chrome ─────────────────────────────────────────────────
        buttonStyleData: ButtonStyleData(
          height: 46,
          width: double.infinity,
          padding: EdgeInsets.only(
            left: widget.prefixIcon != null ? 10 : 12,
            right: 4,
          ),
          decoration: const BoxDecoration(),
          elevation: 0,
        ),

        // ── Underline ─────────────────────────────────────────────────────
        underline: const SizedBox.shrink(),

        // ── Arrow ─────────────────────────────────────────────────────────
        iconStyleData: IconStyleData(
          icon: _Arrow(isOpen: _isOpen, hasValue: hasValue),
          iconSize: 34,
        ),

        // ── Menu ──────────────────────────────────────────────────────────
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          padding: EdgeInsets.only(
            top: widget.isSearchable ? 0 : 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: newBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          elevation: 0,
          offset: const Offset(0, 4),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(3),
            thickness: WidgetStateProperty.all(3),
            thumbVisibility: WidgetStateProperty.all(false),
          ),
        ),

        // ── Menu items ────────────────────────────────────────────────────
        menuItemStyleData: MenuItemStyleData(
         // height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return newBlueLightColor;
            if (states.contains(WidgetState.hovered)) return newBlueLightColor.withValues(alpha: 0.5);
            if (states.contains(WidgetState.pressed)) return newBlueLightColor;
            return null;
          }),
        ),

        // ── Search ────────────────────────────────────────────────────────
        // ── Search ────────────────────────────────────────────────────────
        dropdownSearchData: widget.isSearchable
            ? DropdownSearchData<T>(
          searchController: _searchCtrl,
          searchBarWidgetHeight: 58,        // was: searchInnerWidgetHeight
          searchBarWidget: _SearchBox(controller: _searchCtrl), // was: searchInnerWidget
          searchMatchFn: (item, query) {
            if (item.value == null) return false;
            return widget
                .itemLabel(item.value as T)
                .toLowerCase()
                .contains(query.toLowerCase());
          },
        )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Button inner — shared between hint and selected-item display
// ═══════════════════════════════════════════════════════════════════════════════
class _ButtonInner extends StatelessWidget {
  final String text;
  final bool isHint;
  final IconData? prefixIcon;

  const _ButtonInner({
    required this.text,
    required this.isHint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (prefixIcon != null) ...[
        Icon(
          prefixIcon,
          size: 15,
          color: isHint ? newTextHint : newBlueColor,
        ),
        const SizedBox(width: 7),
      ],
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHint ? FontWeight.w400 : FontWeight.w600,
            color: isHint ? newTextHint : newTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated arrow
// ═══════════════════════════════════════════════════════════════════════════════
class _Arrow extends StatelessWidget {
  final bool isOpen;
  final bool hasValue;

  const _Arrow({required this.isOpen, required this.hasValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedRotation(
        turns: isOpen ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isOpen
                ? newBlueLightColor
                : hasValue
                ? newSurfaceColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isOpen || hasValue ? newBlueColor : newTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Menu item row
// ═══════════════════════════════════════════════════════════════════════════════
class _ItemRow extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _ItemRow({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Left accent bar
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 3,
        height: 20,
        margin: EdgeInsets.only(right: isSelected ? 10 : 13),
        decoration: BoxDecoration(
          color: isSelected ? newBlueColor : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),

      // Label
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? newBlueColor : newTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // Checkmark
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: isSelected
            ? Container(
          key: const ValueKey('chk'),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: newBlueLightColor,
            shape: BoxShape.circle,
            border: Border.all(
                color: newBlueColor.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            size: 11,
            color: newBlueColor,
          ),
        )
            : const SizedBox(
            key: ValueKey('empty'), width: 20, height: 20),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Search box — pinned at top of menu when isSearchable = true
// ═══════════════════════════════════════════════════════════════════════════════
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: newBorderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: TextField(
        controller: controller,
        autofocus: false,
        style: const TextStyle(fontSize: 13, color: newTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search…',
          hintStyle: const TextStyle(fontSize: 13, color: newTextHint),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.search_rounded,
                size: 16, color: newTextSecondary),
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 32, minHeight: 32),
          // Clear button — only visible when there's text
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
              onTap: controller.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.close_rounded,
                    size: 14, color: newTextSecondary),
              ),
            ),
          ),
          suffixIconConstraints:
          const BoxConstraints(minWidth: 28, minHeight: 28),
          filled: true,
          fillColor: newSurfaceColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: newBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: newBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: newBlueColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Skeleton — animated shimmer while data loads
// ═══════════════════════════════════════════════════════════════════════════════
class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final alpha = 0.35 + (_anim.value * 0.45);
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: newBorderColor.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Container(
              width: 110,
              height: 11,
              decoration: BoxDecoration(
                color: newTextHint.withValues(alpha: alpha * 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: newTextHint.withValues(alpha: alpha * 0.28),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ]),
        );
      },
    );
  }
}