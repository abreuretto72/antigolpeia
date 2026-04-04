import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../antigolpe/constants/antigolpe_constants.dart';
import '../data/models/whitelist_item.dart';
import '../services/guard_service.dart';

class WhitelistView extends StatefulWidget {
  const WhitelistView({super.key});

  @override
  State<WhitelistView> createState() => _WhitelistViewState();
}

class _WhitelistViewState extends State<WhitelistView> {
  final _guard = GuardService();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    _phoneController.clear();
    _nameController.clear();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar contato confiável'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Número (ex: +5511999999999)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AntiGolpeConstants.colorSafe,
            ),
            onPressed: () async {
              final phone = _phoneController.text.trim();
              final name = _nameController.text.trim();
              if (phone.isNotEmpty && name.isNotEmpty) {
                await _guard.add(phone, name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(WhitelistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover contato?'),
        content: Text('${item.name} não será mais considerado confiável.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _guard.remove(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AntiGolpeConstants.keyWhitelistTitle),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AntiGolpeConstants.colorSafe,
        onPressed: _showAddDialog,
        tooltip: 'Adicionar contato',
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<WhitelistItem>('antigolpeia_whitelist').listenable(),
        builder: (context, Box<WhitelistItem> box, _) {
          final items = box.values.toList();

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    AntiGolpeConstants.keyWhitelistEmpty,
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AntiGolpeConstants.colorSafe.withValues(alpha: 0.15),
                    child: const Icon(Icons.verified_user, color: AntiGolpeConstants.colorSafe),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.phoneNumber, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AntiGolpeConstants.colorRisk),
                    onPressed: () => _confirmDelete(item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
