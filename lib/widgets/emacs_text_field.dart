/// EmacsTextField — a multiline text field with common Emacs key bindings.
///
// Time-stamp: <Sunday 2026-05-03 21:44:43 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A multiline text field that understands the most commonly used Emacs
/// movement and editing key chords.
///
/// Supported bindings:
///   C-a   beginning of line        C-e   end of line
///   C-f   forward char             C-b   backward char
///   C-d   delete char forward      C-k   kill to end of line
///   C-y   yank (paste killed text) C-w   kill region (cut selection)
///   C-g   cancel / deselect        C-/   undo
///   M-f   forward word             M-b   backward word
///   M-d   kill word forward
///
/// Keys not in the above list are passed through to the underlying [TextField].

class EmacsTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autofocus;
  final bool expands;
  final int? minLines;

  const EmacsTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.autofocus = false,
    this.expands = false,
    this.minLines,
  });

  @override
  State<EmacsTextField> createState() => _EmacsTextFieldState();
}

class _EmacsTextFieldState extends State<EmacsTextField> {
  // Simple single-entry kill ring (Ctrl+K / Ctrl+W → Ctrl+Y).
  String _killRing = '';

  TextEditingController get _ctrl => widget.controller;

  // ── Cursor helpers ─────────────────────────────────────────────────────────

  int get _offset => _ctrl.selection.baseOffset.clamp(0, _ctrl.text.length);

  void _moveTo(int offset, {bool select = false}) {
    final clamped = offset.clamp(0, _ctrl.text.length);
    _ctrl.selection = select
        ? TextSelection(
            baseOffset: _ctrl.selection.baseOffset,
            extentOffset: clamped,
          )
        : TextSelection.collapsed(offset: clamped);
  }

  // ── Line helpers ───────────────────────────────────────────────────────────

  int _lineStart(int at) {
    final text = _ctrl.text;
    if (at == 0) return 0;
    final idx = text.lastIndexOf('\n', at - 1);
    return idx == -1 ? 0 : idx + 1;
  }

  int _lineEnd(int at) {
    final text = _ctrl.text;
    final idx = text.indexOf('\n', at);
    return idx == -1 ? text.length : idx;
  }

  int _nextLine(int at) {
    final text = _ctrl.text;
    final col = at - _lineStart(at);
    final end = _lineEnd(at);
    if (end >= text.length) return text.length;
    final nextStart = end + 1;
    final nextEnd = _lineEnd(nextStart);
    return (nextStart + col).clamp(nextStart, nextEnd);
  }

  int _prevLine(int at) {
    final start = _lineStart(at);
    if (start == 0) return 0;
    final prevEnd = start - 1;
    final prevStart = _lineStart(prevEnd);
    final col = at - start;
    return (prevStart + col).clamp(prevStart, prevEnd);
  }

  // ── Word helpers ───────────────────────────────────────────────────────────

  static bool _isWord(String ch) => RegExp(r'\w').hasMatch(ch);

  int _wordForward(int at) {
    final text = _ctrl.text;
    var i = at;
    while (i < text.length && !_isWord(text[i])) {
      i++;
    }
    while (i < text.length && _isWord(text[i])) {
      i++;
    }
    return i;
  }

  int _wordBackward(int at) {
    final text = _ctrl.text;
    var i = at;
    while (i > 0 && !_isWord(text[i - 1])) {
      i--;
    }
    while (i > 0 && _isWord(text[i - 1])) {
      i--;
    }
    return i;
  }

  // ── Kill helpers ───────────────────────────────────────────────────────────

  void _kill(int from, int to) {
    if (from == to) return;
    final text = _ctrl.text;
    _killRing = text.substring(
      from.clamp(0, text.length),
      to.clamp(0, text.length),
    );
    _ctrl.value = _ctrl.value.copyWith(
      text: text.replaceRange(
        from.clamp(0, text.length),
        to.clamp(0, text.length),
        '',
      ),
      selection: TextSelection.collapsed(offset: from.clamp(0, text.length)),
    );
  }

  void _killSelection() {
    final sel = _ctrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    _kill(sel.start, sel.end);
  }

  // ── Character/text manipulation ────────────────────────────────────────────

  void _deleteForward() {
    final o = _offset;
    if (o >= _ctrl.text.length) return;
    _ctrl.value = _ctrl.value.copyWith(
      text: _ctrl.text.replaceRange(o, o + 1, ''),
      selection: TextSelection.collapsed(offset: o),
    );
  }

  // ── Key event handler ──────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final key = event.logicalKey;

    // Ctrl bindings.
    if (ctrl && !alt) {
      switch (key) {
        case LogicalKeyboardKey.keyA:
          _moveTo(_lineStart(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyE:
          _moveTo(_lineEnd(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyF:
          _moveTo((_offset + 1).clamp(0, _ctrl.text.length));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyB:
          _moveTo((_offset - 1).clamp(0, _ctrl.text.length));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyN:
          _moveTo(_nextLine(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyP:
          _moveTo(_prevLine(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyD:
          _deleteForward();
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyK:
          final start = _offset;
          final end = _lineEnd(start);
          if (start == end && end < _ctrl.text.length) {
            // At end of line — kill the newline.
            _kill(start, start + 1);
          } else {
            _kill(start, end);
          }
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyY:
          if (_killRing.isEmpty) return KeyEventResult.handled;
          final o = _offset;
          _ctrl.value = _ctrl.value.copyWith(
            text: _ctrl.text.replaceRange(o, o, _killRing),
            selection: TextSelection.collapsed(offset: o + _killRing.length),
          );
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyW:
          _killSelection();
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyG:
          _moveTo(_offset); // collapse selection
          return KeyEventResult.handled;

        // Ctrl+Z and Ctrl+/ are NOT intercepted here — Flutter's EditableText
        // Shortcuts widget handles undo natively and must not be overridden.

        default:
          return KeyEventResult.ignored;
      }
    }

    // Alt / Meta bindings.
    if (alt && !ctrl) {
      switch (key) {
        case LogicalKeyboardKey.keyF:
          _moveTo(_wordForward(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyB:
          _moveTo(_wordBackward(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.keyD:
          _kill(_offset, _wordForward(_offset));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.enter:
          // Insert a newline followed by '+ ' to start a new bullet line.
          final o = _offset;
          const insertion = '\n+ ';
          _ctrl.value = _ctrl.value.copyWith(
            text: _ctrl.text.replaceRange(o, o, insertion),
            selection: TextSelection.collapsed(offset: o + insertion.length),
          );
          return KeyEventResult.handled;

        case LogicalKeyboardKey.backspace:
          // M-Backspace — kill word backward.
          _kill(_wordBackward(_offset), _offset);
          return KeyEventResult.handled;

        default:
          return KeyEventResult.ignored;
      }
    }

    return KeyEventResult.ignored;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _onKey,
      child: TextField(
        controller: _ctrl,
        focusNode: widget.focusNode,
        decoration: widget.decoration,
        style: widget.style,
        autofocus: widget.autofocus,
        expands: widget.expands,
        maxLines: widget.expands ? null : null,
        minLines: widget.expands ? null : (widget.minLines ?? 5),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
}
