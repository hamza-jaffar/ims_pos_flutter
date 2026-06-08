import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/services/db_seeder_service.dart';

class QATestingTab extends StatefulWidget {
  const QATestingTab({super.key});

  @override
  State<QATestingTab> createState() => _QATestingTabState();
}

class _QATestingTabState extends State<QATestingTab> {
  bool _isSeeding = false;
  String _statusMessage = 'Ready to run stress tests.';
  double _progress = 0.0;

  Future<void> _runSeedInventory() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Seeding 50,000 products... (This may take a minute)';
      _progress = 0.3;
    });

    try {
      await DbSeederService.instance.seedMassiveInventory(count: 50000);
      setState(() {
        _statusMessage = 'Successfully seeded 50,000 products!';
        _progress = 1.0;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seeding inventory: $e';
        _progress = 0.0;
      });
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  Future<void> _runSeedTransactions() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Seeding 100,000 transactions... (This may take a few minutes)';
      _progress = 0.3;
    });

    try {
      await DbSeederService.instance.seedMassiveTransactions(count: 100000);
      setState(() {
        _statusMessage = 'Successfully seeded 100,000 transactions!';
        _progress = 1.0;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error seeding transactions: $e';
        _progress = 0.0;
      });
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  Future<void> _runTruncate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Database?', style: TextStyle(color: AppColors.danger)),
        content: const Text('This will delete ALL products and sales from the database immediately. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSeeding = true;
        _statusMessage = 'Clearing database...';
        _progress = 0.5;
      });
      try {
        await DbSeederService.instance.truncateAll();
        setState(() {
          _statusMessage = 'Database cleared successfully.';
          _progress = 1.0;
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Error clearing DB: $e';
          _progress = 0.0;
        });
      } finally {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QA & Stress Testing Tools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use these tools to verify the application\'s performance under high loads. '
            'Do not use these tools on a production database as they inject dummy data.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          
          if (_isSeeding) ...[
            LinearProgressIndicator(value: _progress, color: AppColors.primary),
            const SizedBox(height: 12),
          ],
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Cards
          _buildActionCard(
            title: '1. Seed Massive Inventory',
            description: 'Generates 50,000 random products with barcodes and prices to test Search and POS Grid latency.',
            icon: Icons.inventory_2,
            buttonText: 'Inject Products',
            color: AppColors.primary,
            onPressed: _isSeeding ? null : _runSeedInventory,
          ),
          const SizedBox(height: 16),
          
          _buildActionCard(
            title: '2. Seed Massive Transactions',
            description: 'Generates 100,000 completed sales records to test Sales History loading times and chart aggregations.',
            icon: Icons.receipt_long,
            buttonText: 'Inject Sales',
            color: Colors.green,
            onPressed: _isSeeding ? null : _runSeedTransactions,
          ),
          const SizedBox(height: 16),
          
          _buildActionCard(
            title: '3. Danger Zone: Wipe Data',
            description: 'Deletes all products, sales, and purchases. Resets the DB for a clean test.',
            icon: Icons.delete_forever,
            buttonText: 'Clear DB',
            color: AppColors.danger,
            onPressed: _isSeeding ? null : _runTruncate,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required Color color,
    required VoidCallback? onPressed,
    bool isDanger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.white : color,
              foregroundColor: isDanger ? color : Colors.white,
              side: isDanger ? BorderSide(color: color) : null,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
