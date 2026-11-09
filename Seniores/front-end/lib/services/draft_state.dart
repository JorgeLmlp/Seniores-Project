import 'dart:async';
import 'package:flutter/material.dart';
import 'local_store.dart';
import 'session_service.dart';

/// Rascunhos separados por conta, paciente e formulário. Nunca guarda senhas.
mixin DraftState<T extends StatefulWidget> on State<T> {
  Map<String, TextEditingController> get draftControllers;
  Map<String, dynamic> get draftValues => {};
  void restoreDraftValues(Map<String, dynamic> values) {}
  String get draftName => widget.runtimeType.toString();
  late String _scope, _key;
  bool _loaded = false, _changed = false, _finished = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    final session = SessionService.instance;
    _scope = session.escopo;
    _key = 'draft:${session.pacienteId}:$draftName';
    for (final c in draftControllers.values) {
      c.addListener(_change);
    }
    _restore();
  }

  Future<void> _restore() async {
    try {
      // Aguarda os valores iniciais definidos pelo formulário em initState.
      await Future<void>.value();
      final baseline = draftControllers.map((k, v) => MapEntry(k, v.text));
      final stored = await LocalStore.instance.get(_scope, _key);
      if (!mounted ||
          stored is! Map ||
          draftControllers.entries.any((e) => e.value.text != baseline[e.key])) {
        return;
      }
      for (final entry in draftControllers.entries) {
        if (stored['text']?[entry.key] is String) {
          entry.value.text = stored['text'][entry.key];
        }
      }
      restoreDraftValues(Map<String, dynamic>.from(stored['values'] ?? {}));
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Não foi possível abrir o armazenamento temporário.')));
      }
    } finally {
      _loaded = true;
    }
  }

  void _change() {
    if (!_loaded) {
      _changed = true;
      return;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), _save);
  }

  Future<void> _save() async {
    if (_finished ||
        SessionService.instance.escopo != _scope ||
        (!_loaded && !_changed)) { return;
    }
    final value = {
      'text': draftControllers.map((k, v) => MapEntry(k, v.text)),
      'values': draftValues
    };
    try {
      await LocalStore.instance.put(_scope, _key, value);
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    _finished = true;
    _timer?.cancel();
    try {
      await LocalStore.instance.remove(_scope, _key);
    } catch (_) {}
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_loaded) _change();
  }

  /// Chamar antes de destruir os TextEditingControllers.
  void saveDraftBeforeDispose() {
    _timer?.cancel();
    _save();
    for (final c in draftControllers.values) {
      c.removeListener(_change);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
