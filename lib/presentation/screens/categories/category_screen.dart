import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/icon_registry.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_event.dart';
import '../../blocs/category/category_state.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryLoadRequested());
  }

  void _showAddDialog({Category? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.type ?? 'expense';
    String selectedIcon = existing?.icon ?? 'category';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Kategori' : 'Tambah Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showIconPicker(ctx, setDialogState, (icon) {
                  selectedIcon = icon;
                  setDialogState(() {});
                }),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ikon',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Icon(CategoryIconRegistry.get(selectedIcon), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        selectedIcon == 'category' ? 'Pilih ikon...' : selectedIcon,
                        style: TextStyle(
                          color: selectedIcon == 'category'
                              ? Colors.grey
                              : null,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final cat = Category(
                  id: existing?.id,
                  name: name,
                  type: selectedType,
                  icon: selectedIcon,
                );
                if (existing != null) {
                  context.read<CategoryBloc>().add(
                    CategoryUpdated(id: existing.safeId, category: cat),
                  );
                } else {
                  context.read<CategoryBloc>().add(CategoryCreated(category: cat));
                }
                Navigator.pop(ctx);
              },
              child: Text(existing != null ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(
    BuildContext dialogCtx,
    void Function(VoidCallback) setDialogState,
    void Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: dialogCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final entries = CategoryIconRegistry.all;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Pilih Ikon',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          onSelect(entry.key);
                          Navigator.pop(sheetCtx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(entry.value, size: 24),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Kategori'),
        ),
        child: _buildBody(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CategoryLoaded) {
          final expense = state.expenseCategories;
          final income = state.incomeCategories;

          if (expense.isEmpty && income.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori. Tap + untuk menambah.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expense.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pengeluaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...expense.map((cat) => _buildCategoryTile(cat, Colors.red)),
                const SizedBox(height: 24),
              ],
              if (income.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pemasukan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...income.map((cat) => _buildCategoryTile(cat, Colors.green)),
              ],
            ],
          );
        }
        if (state is CategoryError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoryTile(Category cat, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_iconData(cat.icon), size: 20, color: accentColor),
        ),
        title: Text(cat.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showAddDialog(existing: cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () async {
                if (await _confirmDelete(cat.name)) {
                  if (mounted) {
                    context.read<CategoryBloc>().add(
                      CategoryDeleted(id: cat.safeId),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String icon) => CategoryIconRegistry.get(icon);
}
