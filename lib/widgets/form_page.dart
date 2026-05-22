import 'package:flutter/material.dart';

// ── 表單頁 Scaffold（左上角箭頭返回，米白/霧藍背景） ─────────────
class FormPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottomButton;
  final EdgeInsets padding;

  const FormPage({
    super.key,
    required this.title,
    required this.children,
    this.bottomButton,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 32),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            if (bottomButton != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: bottomButton!,
              ),
          ],
        ),
      ),
    );
  }
}

// ── 分組欄位卡片（圓弧白底） ─────────────────────────────────────
class FormSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const FormSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(children.length, (i) {
              return Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 0,
                      color: theme.dividerColor.withOpacity(0.6),
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── 普通文字輸入行 ────────────────────────────────────────────────
class FormFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const FormFieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.4),
              width: 1,
            ),
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

// ── 選擇行（點擊進入下一頁或彈 picker） ──────────────────────────
class FormTapRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;
  final Widget? leading;

  const FormTapRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withOpacity(0.4);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}

// ── Toggle 行（Switch） ───────────────────────────────────────────
class FormSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const FormSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── 選項組（橫排按鈕） ────────────────────────────────────────────
class FormChoiceRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final List<Color> colors;
  final ValueChanged<String> onChanged;

  const FormChoiceRow({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(options.length, (i) {
          final sel = selected == options[i];
          final color = colors[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withOpacity(0.18)
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: sel ? color : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 儲存按鈕 ─────────────────────────────────────────────────────
class FormSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const FormSaveButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}

// ── Chip 標籤清單（用藥等動態列表） ──────────────────────────────
class FormChipList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<int> onRemove;

  const FormChipList({super.key, required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: items.asMap().entries.map((e) {
          return InputChip(
            label: Text(e.value, style: const TextStyle(fontSize: 12)),
            onDeleted: () => onRemove(e.key),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}
