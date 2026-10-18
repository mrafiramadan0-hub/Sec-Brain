import 'package:flutter/material.dart';

import '../main.dart';
import '../services/backup_service.dart';

Future<void> showBackupDialog(BuildContext context, BrainStore store) async {
  await showDialog(
    context: context,
    builder: (context) => _BackupDialog(store: store),
  );
}

class _BackupDialog extends StatefulWidget {
  const _BackupDialog({required this.store});
  final BrainStore store;

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();
  bool _importError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentTint = isDark
        ? widget.store.accentColor.withValues(alpha: 0.2)
        : widget.store.accentColor.withValues(alpha: 0.12);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark
          ? const Color(0xFF1D2420)
          : Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sync_alt,
                      color: widget.store.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ekspor & Impor Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Penyimpanan & migrasi data SecBrain secara mandiri',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: widget.store.accentColor,
                labelColor: widget.store.accentColor,
                unselectedLabelColor: muted,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.upload_file, size: 18),
                    text: 'Ekspor Data',
                  ),
                  Tab(
                    icon: Icon(Icons.download, size: 18),
                    text: 'Impor / Restore',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Ekspor Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExportCard(
                            title: 'Ekspor Seluruh Data (JSON)',
                            desc: 'Mencakup seluruh Tugas, Catatan, Jadwal Kuliah, Keuangan, dan Habits dalam format JSON.',
                            icon: Icons.data_object,
                            buttonLabel: 'Salin JSON ke Clipboard',
                            onTap: () {
                              final jsonStr = BackupService.exportAllToJson(
                                widget.store,
                              );
                              BackupService.copyToClipboard(
                                context,
                                jsonStr,
                                'Seluruh data JSON berhasil disalin ke Clipboard!',
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildExportCard(
                            title: 'Ekspor Transaksi Keuangan (CSV)',
                            desc: 'Rekap transaksi pemasukan dan pengeluaran yang siap dibuka di Microsoft Excel atau Google Sheets.',
                            icon: Icons.table_chart_outlined,
                            buttonLabel: 'Salin CSV Transaksi',
                            onTap: () {
                              final csvStr =
                                  BackupService.exportTransactionsToCsv(
                                    widget.store,
                                  );
                              BackupService.copyToClipboard(
                                context,
                                csvStr,
                                'Laporan transaksi CSV berhasil disalin ke Clipboard!',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Impor Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tempelkan teks data backup JSON di bawah ini:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _importController,
                            maxLines: 8,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.white : ink,
                            ),
                            decoration: InputDecoration(
                              hintText: '{\n  "app": "SecBrain",\n  "tasks": [...]\n}',
                              hintStyle: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF26322C)
                                  : paper,
                              errorText: _importError
                                  ? 'Format JSON tidak valid atau rusak'
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: coral,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Proses impor akan menggantikan data yang ada saat ini dengan data backup.',
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.store.accentColor,
                              ),
                              onPressed: () {
                                final text = _importController.text.trim();
                                if (text.isEmpty) return;

                                final success = BackupService.importFromJson(
                                  text,
                                  widget.store,
                                );
                                if (success) {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  Navigator.pop(context);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Data berhasil di-restore dengan sempurna!',
                                      ),
                                      backgroundColor: widget.store.accentColor,
                                    ),
                                  );
                                } else {
                                  setState(() => _importError = true);
                                }
                              },
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('Terapkan Restore'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String desc,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26322C) : paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF37463E) : const Color(0xFFE6EAE5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.store.accentColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 11, color: muted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.store.accentColor,
              side: BorderSide(color: widget.store.accentColor),
            ),
            onPressed: onTap,
            icon: const Icon(Icons.copy, size: 14),
            label: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
