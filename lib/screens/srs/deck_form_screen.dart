import 'package:flutter/material.dart';

import '../../models/deck.dart';
import '../../services/api_client.dart';

class DeckFormScreen extends StatefulWidget {
  final Deck? deck;

  const DeckFormScreen({super.key, this.deck});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  String _cardType = 'kosakata';
  String _color = '#4F6EF7';
  bool _loading = false;

  static const _colors = ['#4F6EF7', '#E8604C', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899'];

  bool get _isEdit => widget.deck != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.deck?.name ?? '');
    _description = TextEditingController(text: widget.deck?.description ?? '');
    _cardType = widget.deck?.cardType ?? 'kosakata';
    _color = widget.deck?.color ?? '#4F6EF7';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/decks/${widget.deck!.id}', {
          'name': _name.text.trim(),
          'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
          'color': _color,
          'card_type': _cardType,
        });
      } else {
        await ApiClient.instance.post('/decks', {
          'name': _name.text.trim(),
          'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
          'color': _color,
          'card_type': _cardType,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Deck' : 'Deck Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama deck'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text('Tipe kartu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kosakata', label: Text('Kosakata')),
                  ButtonSegment(value: 'kanji', label: Text('Kanji')),
                  ButtonSegment(value: 'klip', label: Text('Klip')),
                ],
                selected: {_cardType},
                onSelectionChanged: (s) => setState(() => _cardType = s.first),
              ),
              const SizedBox(height: 20),
              const Text('Warna', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _colors
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => setState(() => _color = c),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Deck.hexToColor(c),
                                shape: BoxShape.circle,
                                border: _color == c
                                    ? Border.all(color: Colors.black87, width: 3)
                                    : null,
                              ),
                              child: _color == c
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Buat Deck'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
