import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';

/// A generic searchable dropdown item.
class SearchableDropdownItem<T> {
  final T value;
  final String label;

  const SearchableDropdownItem({required this.value, required this.label});
}

/// A form-friendly searchable dropdown.
/// Tapping it opens a search dialog so users can filter long lists quickly.
class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final bool isRequired;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.selectedValue,
    this.isRequired = false,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  String? _errorText;

  String? get _selectedLabel {
    if (widget.selectedValue == null) return null;
    final match = widget.items
        .where((i) => i.value == widget.selectedValue)
        .toList();
    return match.isEmpty ? null : match.first.label;
  }

  Future<void> _openSearchDialog(FormFieldState<T> state) async {
    final selected = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => _SearchDialog<T>(
        label: widget.label,
        items: widget.items,
        selectedValue: widget.selectedValue,
      ),
    );
    // dialog returns special _ClearValue sentinel for "clear"
    if (selected is _ClearValue) {
      state.didChange(null);
      widget.onChanged(null);
      setState(() => _errorText = null);
      return;
    }
    if (selected != null) {
      state.didChange(selected as T);
      widget.onChanged(selected);
      if (widget.isRequired) setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _selectedLabel;
    return FormField<T>(
      initialValue: widget.selectedValue,
      validator: (_) {
        if (widget.isRequired && widget.selectedValue == null) {
          return 'This field is required.';
        }
        return null;
      },
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openSearchDialog(state),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasError ? AppColors.danger : AppColors.border,
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label ?? widget.hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: label != null
                              ? AppColors.textMain
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.selectedValue != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          state.didChange(null);
                          widget.onChanged(null);
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 4,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Sentinel type used to signal "clear selection"
class _ClearValue {}

class _SearchDialog<T> extends StatefulWidget {
  final String label;
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;

  const _SearchDialog({
    required this.label,
    required this.items,
    this.selectedValue,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  final _searchController = TextEditingController();
  List<SearchableDropdownItem<T>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
                .where((i) => i.label.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select ${widget.label}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.label.toLowerCase()}...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ),
            // Clear selection option
            if (widget.selectedValue != null)
              InkWell(
                onTap: () => Navigator.of(context).pop(_ClearValue()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.clear, size: 16, color: AppColors.danger),
                      SizedBox(width: 10),
                      Text(
                        'Clear selection',
                        style: TextStyle(fontSize: 13, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
            // List
            Flexible(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: AppColors.textSecondary.withAlpha(100),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No results found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, index) {
                        final item = _filtered[index];
                        final isSelected = item.value == widget.selectedValue;
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMain,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
