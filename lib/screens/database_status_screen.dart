// lib/screens/database_status_screen.dart
import 'package:flutter/material.dart';
import '../supabase_service.dart';
import '../config/supabase_config.dart';

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  State<DatabaseStatusScreen> createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Status'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: ValueListenableBuilder<DatabaseStatus>(
        valueListenable: _supabaseService.connectionStatusNotifier,
        builder: (context, connectionStatus, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConnectionStatusCard(connectionStatus),
                const SizedBox(height: 16),
                _buildTablesStatusSection(),
                const SizedBox(height: 16),
                _buildQuickActionsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatusCard(DatabaseStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case DatabaseStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Connected';
        break;
      case DatabaseStatus.disconnected:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Disconnected';
        break;
      case DatabaseStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Error';
        break;
      case DatabaseStatus.initializing:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Initializing';
        break;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Connection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supabase Backend',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesStatusSection() {
    return ValueListenableBuilder<List<DatabaseInfo>>(
      valueListenable: _supabaseService.tableStatusesNotifier,
      builder: (context, tableStatuses, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Database Tables',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (tableStatuses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No table information available'),
                    ),
                  )
                else
                  ...tableStatuses.map((table) => _buildTableStatusItem(table)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableStatusItem(DatabaseInfo table) {
    Color statusColor;
    IconData statusIcon;

    switch (table.status) {
      case TableStatus.exists:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case TableStatus.missing:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_outlined;
        break;
      case TableStatus.creating:
        statusColor = Colors.blue;
        statusIcon = Icons.build_circle_outlined;
        break;
      case TableStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.tableName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Records: ${table.recordCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (table.lastUpdated != null)
                      Text(
                        'Updated: ${_formatTime(table.lastUpdated!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                if (table.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${table.errorMessage}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  'Refresh Status',
                  Icons.refresh,
                  Colors.blue,
                  _refreshStatus,
                ),
                _buildActionButton(
                  'Test Connection',
                  Icons.wifi_find,
                  Colors.green,
                  _testConnection,
                ),
                _buildActionButton(
                  'Add Sample Data',
                  Icons.add_circle_outline,
                  Colors.orange,
                  _addSampleData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isRefreshing ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    try {
      await _supabaseService.refreshDatabaseStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database status refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isRefreshing = true);
    try {
      if (SupabaseConfig.useDemoMode) {
        // In demo mode, just pretend the connection test was successful
        await Future.delayed(
            const Duration(milliseconds: 800)); // Simulate delay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test successful (Demo Mode)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // In real mode, actually test the connection
        await _supabaseService.supabase
            .from('rice_weight')
            .select('id')
            .limit(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test successful'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _addSampleData() async {
    setState(() => _isRefreshing = true);
    try {
      if (SupabaseConfig.useDemoMode) {
        // In demo mode, just pretend we added data
        await Future.delayed(
            const Duration(milliseconds: 800)); // Simulate delay
        await _refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data added successfully (Demo Mode)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // In real mode, actually add data
        await _supabaseService.supabase.from('rice_weight').insert([
          {
            'weight_grams': 3500 + (DateTime.now().millisecond % 1000),
            'level_state': 'partial',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]);

        await _refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
