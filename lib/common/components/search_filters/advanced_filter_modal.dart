import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/query/query_filter_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/responsive_field_row.dart';
import '../../widgets/app_dropdown.dart';

class FilterableFieldDefinition {
  final String field;
  final String label;
  final List<FilterOperator> supportedOperators;

  const FilterableFieldDefinition({
    required this.field,
    required this.label,
    this.supportedOperators = const [
      FilterOperator.equals,
      FilterOperator.notEquals,
      FilterOperator.contains,
      FilterOperator.startsWith,
      FilterOperator.greaterThan,
      FilterOperator.lessThan,
      FilterOperator.between,
    ],
  });
}

class AdvancedFilterModal extends StatefulWidget {
  final List<FilterDescriptor> initialFilters;
  final List<FilterableFieldDefinition> availableFields;
  final ValueChanged<List<FilterDescriptor>> onApply;

  const AdvancedFilterModal({
    super.key,
    required this.initialFilters,
    required this.availableFields,
    required this.onApply,
  });

  @override
  State<AdvancedFilterModal> createState() => _AdvancedFilterModalState();
}

class _AdvancedFilterModalState extends State<AdvancedFilterModal> {
  late List<_EditableRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = widget.initialFilters.map((f) {
      return _EditableRule(
        field: f.field,
        label: f.label,
        operator: f.operator,
        valueController: TextEditingController(text: f.value?.toString() ?? ''),
        secondValueController: TextEditingController(text: f.secondValue?.toString() ?? ''),
      );
    }).toList();

    if (_rules.isEmpty && widget.availableFields.isNotEmpty) {
      _addNewRule();
    }
  }

  @override
  void dispose() {
    for (final r in _rules) {
      r.dispose();
    }
    super.dispose();
  }

  void _addNewRule() {
    if (widget.availableFields.isEmpty) return;
    final first = widget.availableFields.first;
    setState(() {
      _rules.add(_EditableRule(
        field: first.field,
        label: first.label,
        operator: first.supportedOperators.first,
        valueController: TextEditingController(),
        secondValueController: TextEditingController(),
      ));
    });
  }

  void _removeRule(int index) {
    setState(() {
      _rules[index].dispose();
      _rules.removeAt(index);
    });
  }

  void _apply() {
    final List<FilterDescriptor> applied = [];
    for (final r in _rules) {
      final val = r.valueController.text.trim();
      final secVal = r.secondValueController.text.trim();
      if (val.isNotEmpty || r.operator == FilterOperator.isNull || r.operator == FilterOperator.isNotNull) {
        dynamic parsedVal = double.tryParse(val) ?? val;
        dynamic parsedSecVal = double.tryParse(secVal) ?? secVal;

        applied.add(FilterDescriptor(
          field: r.field,
          label: r.label,
          operator: r.operator,
          value: parsedVal,
          secondValue: parsedSecVal,
          isActive: true,
        ));
      }
    }
    widget.onApply(applied);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    widget.onApply([]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primaryYellowDark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Advanced Query Builder',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Construct custom filtering rules across available record attributes',
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spacing16),

              // Rules List
              Expanded(
                child: _rules.isEmpty
                    ? Center(
                        child: Text(
                          'No active rules. Tap below to add a filter.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _rules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing12),
                        itemBuilder: (context, index) {
                          final rule = _rules[index];
                          return _buildRuleRow(context, rule, index, isDark);
                        },
                      ),
              ),

              const SizedBox(height: AppDimensions.spacing16),
              // Add Rule button
              TextButton.icon(
                onPressed: _addNewRule,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Rule Condition'),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spacing16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All Rules', style: TextStyle(color: AppColors.error)),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellowDark,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _apply,
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(BuildContext context, _EditableRule rule, int index, bool isDark) {
    final currentFieldDef = widget.availableFields.firstWhere(
      (f) => f.field == rule.field,
      orElse: () => widget.availableFields.first,
    );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Builder(
        builder: (rowContext) {
          final fieldDropdown = AppDropdown<String>(
            label: 'Field',
            value: rule.field,
            isDense: true,
            items: widget.availableFields.map((f) => f.field).toList(),
            itemLabel: (f) {
              final match = widget.availableFields.where((def) => def.field == f);
              if (match.isNotEmpty) return match.first.label;
              return f;
            },
            onChanged: (val) {
              if (val != null) {
                final def = widget.availableFields.firstWhere((f) => f.field == val);
                setState(() {
                  rule.field = val;
                  rule.label = def.label;
                  rule.operator = def.supportedOperators.first;
                });
              }
            },
          );

          final operatorDropdown = AppDropdown<FilterOperator>(
            label: 'Operator',
            value: rule.operator,
            isDense: true,
            items: currentFieldDef.supportedOperators,
            itemLabel: (op) => op.label,
            onChanged: (val) {
              if (val != null) setState(() => rule.operator = val);
            },
          );

          final valueFields = <Widget>[
            if (rule.operator != FilterOperator.isNull && rule.operator != FilterOperator.isNotNull) ...[
              TextField(
                controller: rule.valueController,
                decoration: InputDecoration(
                  labelText: rule.operator == FilterOperator.between ? 'From' : 'Value',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: AppTypography.captionLarge,
              ),
              if (rule.operator == FilterOperator.between)
                TextField(
                  controller: rule.secondValueController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: AppTypography.captionLarge,
                ),
            ],
          ];

          final deleteButton = IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            onPressed: () => _removeRule(index),
            tooltip: 'Remove rule',
          );

          // Narrow screens: one control per line — four side-by-side controls
          // leave each rule field too small to read or tap.
          if (rowContext.isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveFieldRow(children: [fieldDropdown, operatorDropdown, ...valueFields]),
                Align(alignment: Alignment.centerRight, child: deleteButton),
              ],
            );
          }

          return Row(
            children: [
              // Field Dropdown
              Expanded(flex: 2, child: fieldDropdown),
              const SizedBox(width: 8),

              // Operator Dropdown
              Expanded(flex: 2, child: operatorDropdown),
              const SizedBox(width: 8),

              // Value Input (or two inputs if between)
              ...valueFields.expand((field) => [Expanded(flex: 2, child: field), const SizedBox(width: 8)]),
              if (valueFields.isEmpty) const Spacer(flex: 2),

              // Delete Rule
              deleteButton,
            ],
          );
        },
      ),
    );
  }
}

class _EditableRule {
  String field;
  String label;
  FilterOperator operator;
  final TextEditingController valueController;
  final TextEditingController secondValueController;

  _EditableRule({
    required this.field,
    required this.label,
    required this.operator,
    required this.valueController,
    required this.secondValueController,
  });

  void dispose() {
    valueController.dispose();
    secondValueController.dispose();
  }
}
