import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// A reusable searchable dropdown (built on dropdown_button2).
/// Generic over value type T; each option is (value, label).
class DdOption<T> {
  final T value;
  final String label;
  const DdOption(this.value, this.label);
}

class SearchableDropdown<T> extends StatefulWidget {
  final String hint;
  final List<DdOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;

  const SearchableDropdown({
    Key? key,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _search = TextEditingController();

  static const _primary = Color(0xFF5B5BD6);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        hint: Text(widget.hint,
            style: const TextStyle(fontSize: 13, color: _sub)),
        value: widget.value,
        items: widget.options
            .map((o) => DropdownMenuItem<T>(
                  value: o.value,
                  child: Text(o.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _text)),
                ))
            .toList(),
        onChanged: widget.onChanged,
        buttonStyleData: ButtonStyleData(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _sub)),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 320,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        ),
        menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 14)),
        dropdownSearchData: DropdownSearchData<T>(
          searchController: _search,
          searchInnerWidgetHeight: 54,
          searchInnerWidget: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: TextField(
              controller: _search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search...',
                hintStyle: const TextStyle(fontSize: 13, color: _sub),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primary)),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            final label = (item.child is Text)
                ? ((item.child as Text).data ?? '')
                : '';
            return label.toLowerCase().contains(searchValue.toLowerCase());
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) _search.clear();
        },
      ),
    );
  }
}
