// lib/screens/database_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/sql_generator.dart';
import '../database/database_utility.dart';
import '../supabase_service.dart';

class DatabaseManagementScreen extends StatefulWidget {
  const DatabaseManagementScreen({super.key});

  @override
  State<DatabaseManagementScreen> createState() =>
      _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  final _supabaseService = SupabaseService();
  Map<String, dynamic>? _databaseStats;
  bool _isLoading = false;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  Future<void> _loadDatabaseStats() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> stats;

      if (_supabaseService.isDemoMode) {
        // Use supabase service for demo stats
        stats = await _supabaseService.getDatabaseStats();
      } else {
        // Use real database utility
        final utility = DatabaseUtility(_supabaseService.supabase);
        stats = await utility.getDatabaseStats();
      }

      setState(() => _databaseStats = stats);
    } catch (e) {
      setState(() => _output = 'Error loading stats: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildSqlGenerationSection(),
            const SizedBox(height: 24),
            _buildOutputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Database Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadDatabaseStats,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_databaseStats != null)
              _buildStatsContent()
            else
              const Text('No statistics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final stats = _databaseStats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Demo mode indicator
        if (stats['demo_mode'] == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'DEMO MODE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        const Text('Table Record Counts:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (stats['table_counts'] != null)
          ...stats['table_counts'].entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text('${entry.key}: ${entry.value} records'),
              )),
        const SizedBox(height: 12),
        const Text('Recent Activity (24h):',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (stats['recent_activity'] != null)
          ...stats['recent_activity'].entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text('${entry.key}: ${entry.value}'),
              )),
      ],
    );
  }

  Widget _buildSqlGenerationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'SQL Generation Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _generateSql('schema'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Generate Schema'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSql('sample'),
                  icon: const Icon(Icons.data_object),
                  label: const Text('Generate Sample Data'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSql('cleanup'),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Generate Cleanup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSql('stats'),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Generate Stats Query'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSql('all'),
                  icon: const Icon(Icons.all_inclusive),
                  label: const Text('Generate All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Generated SQL Output',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_output.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(_output),
                    tooltip: 'Copy to clipboard',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty
                      ? 'No output yet. Click a button above to generate SQL.'
                      : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateSql(String type) {
    setState(() {
      switch (type) {
        case 'schema':
          _output = SqlGenerator.generateAllTables();
          break;
        case 'sample':
          _output = SqlGenerator.generateSampleData();
          break;
        case 'cleanup':
          _output = SqlGenerator.generateCleanupScript();
          break;
        case 'stats':
          _output = SqlGenerator.generateStatsQuery();
          break;
        case 'all':
          _output = '''${SqlGenerator.generateAllTables()}

${SqlGenerator.generateSampleData()}

${SqlGenerator.generateStatsQuery()}''';
          break;
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SQL copied to clipboard!')),
    );
  }
}
