import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import '../../antigolpe/constants/antigolpe_constants.dart';
import '../core/utils/phone_utils.dart';
import '../services/guard_service.dart';

/// Resultado tipado retornado pela tela de seleção de contatos.
class ContactPickerResult {
  final bool success;
  final int addedCount;

  const ContactPickerResult({required this.success, required this.addedCount});
}

/// Tela de seleção múltipla de contatos do dispositivo.
///
/// Retorna [ContactPickerResult] via `Navigator.pop`.
/// Cada telefone do contato selecionado é normalizado e salvo como
/// um [WhitelistItem] separado — garante match mesmo com números duplicados
/// em formatos diferentes (ex: com e sem +55).
class ContactPickerView extends StatefulWidget {
  const ContactPickerView({super.key});

  @override
  State<ContactPickerView> createState() => _ContactPickerViewState();
}

class _ContactPickerViewState extends State<ContactPickerView> {
  /// Future cacheado em initState — evita re-fetch a cada rebuild.
  late final Future<List<Contact>> _contactsFuture;

  final Set<String> _selectedIds = {};
  final Map<String, Contact> _selectedContacts = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _contactsFuture = FlutterContacts.getContacts(withProperties: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleToggle(Contact contact, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(contact.id);
        _selectedContacts[contact.id] = contact;
      } else {
        _selectedIds.remove(contact.id);
        _selectedContacts.remove(contact.id);
      }
    });
  }

  Future<void> _confirmSelection() async {
    final guard = GuardService();
    int added = 0;

    for (final contact in _selectedContacts.values) {
      final name = contact.displayName;
      for (final phone in contact.phones) {
        final normalized = PhoneUtils.normalize(phone.number);
        if (normalized.isNotEmpty) {
          await guard.add(
              normalized, name.isNotEmpty ? name : normalized);
          added++;
        }
      }
    }

    if (mounted) {
      Navigator.pop(context, ContactPickerResult(success: true, addedCount: added));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AntiGolpeConstants.keyContactsPickerTitle),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_selectedIds.length} selecionado(s)',
                  style: const TextStyle(
                    color: AntiGolpeConstants.colorSafe,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AntiGolpeConstants.keyContactsPickerSearch,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase().trim()),
              ),
            ),

            // Lista de contatos
            Expanded(
              child: FutureBuilder<List<Contact>>(
                future: _contactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            AntiGolpeConstants.keyContactsPickerLoading,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        AntiGolpeConstants.keyContactsPickerError,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final contacts = (snapshot.data ?? [])
                      .where((c) => c.phones.isNotEmpty)
                      .where((c) =>
                          _searchQuery.isEmpty ||
                          c.displayName
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList()
                    ..sort((a, b) =>
                        a.displayName.compareTo(b.displayName));

                  if (contacts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            AntiGolpeConstants.keyContactsPickerEmpty,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // ListView.builder: renderiza apenas os itens visíveis —
                  // performance ideal para listas longas no SM-A256E.
                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final isSelected = _selectedIds.contains(contact.id);
                      final phone = contact.phones.first.number;
                      final initial = contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?';

                      return CheckboxListTile(
                        activeColor: AntiGolpeConstants.colorSafe,
                        checkColor: Colors.white,
                        value: isSelected,
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? AntiGolpeConstants.colorSafe
                                  .withValues(alpha: 0.2)
                              : Colors.grey.shade800,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: isSelected
                                  ? AntiGolpeConstants.colorSafe
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          phone,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (v) => _handleToggle(contact, v),
                      );
                    },
                  );
                },
              ),
            ),

            // Botão de confirmação fixo fora do scroll — nunca sofre overflow
            _ConfirmButton(
              selectedCount: _selectedIds.length,
              onConfirm: _selectedIds.isEmpty ? null : _confirmSelection,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onConfirm;

  const _ConfirmButton({required this.selectedCount, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final label = selectedCount == 0
        ? AntiGolpeConstants.keyContactsPickerConfirmEmpty
        : '${AntiGolpeConstants.keyContactsPickerConfirm} ($selectedCount)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AntiGolpeConstants.colorSafe,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade800,
            disabledForegroundColor: Colors.white38,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
