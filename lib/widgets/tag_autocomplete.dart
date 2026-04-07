/// TagAutocomplete — autocomplete that suggests existing values but accepts
/// free text input.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

/// A section label styled for edit forms, with optional tooltip.

Widget editSectionLabel(BuildContext context, String text, {String? tooltip}) {
  final label = Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.5,
    ),
  );
  if (tooltip == null) return label;

  return Row(
    children: [
      label,
      const Gap(4),
      MarkdownTooltip(
        message: tooltip,
        child: Icon(
          Icons.info_outline,
          size: 13,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    ],
  );
}

/// An autocomplete field that suggests [options] but accepts any typed value.

class TagAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final String hintText;
  final bool autofocus;

  const TagAutocomplete({
    super.key,
    required this.controller,
    required this.options,
    required this.hintText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Autocomplete<String>(
      initialValue: controller.value,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return options;

        return options.where((o) => o.toLowerCase().contains(query)).toList();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        fieldController.addListener(
          () => controller.text = fieldController.text,
        );

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          autofocus: autofocus,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: hintText,
            suffixIcon: options.isNotEmpty
                ? Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 0,
            ),
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 220),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(option, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (value) => controller.text = value,
    );
  }
}
