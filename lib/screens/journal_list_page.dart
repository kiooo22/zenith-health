import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'journal_detail_page.dart';
import 'journal_edit_page.dart';
import '../theme/app_theme.dart';
import '../widgets/main_bottom_nav.dart';

class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  final _journalService = JournalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Jurnal"),
        actions: [
          IconButton(
            tooltip: 'Tulis jurnal baru',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, '/journals'),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.softBackground(Theme.of(context).colorScheme),
        child: StreamBuilder<List<JournalEntry>>(
          stream: _journalService.getJournals(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Terjadi kesalahan"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final journals = snapshot.data!;
            if (journals.isEmpty) {
              return const Center(child: Text("Belum ada jurnal"));
            }

            return ListView.builder(
              itemCount: journals.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final journal = journals[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    title: Text(
                      journal.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        journal.content.length > 70
                            ? "${journal.content.substring(0, 70)}..."
                            : journal.content,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editJournal(context, journal);
                        } else if (value == 'delete') {
                          _deleteJournal(context, journal);
                        } else if (value == 'view') {
                          _viewJournal(context, journal);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('Lihat'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _viewJournal(context, journal),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  void _viewJournal(BuildContext context, JournalEntry journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalDetailPage(journal: journal),
      ),
    );
  }

  void _editJournal(BuildContext context, JournalEntry journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEditPage(journal: journal),
      ),
    );
  }

  void _deleteJournal(BuildContext context, JournalEntry journal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Jurnal?"),
        content: Text(
          'Yakin ingin menghapus jurnal "${journal.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journalService.deleteJournal(journal.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jurnal berhasil dihapus")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
