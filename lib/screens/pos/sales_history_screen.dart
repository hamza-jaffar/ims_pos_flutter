import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';

class SalesHistoryScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const SalesHistoryScreen({super.key, required this.onRouteSelected});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ───────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  List<Purchase> _all = [];
  List<Purchase> _filtered = [];
  bool _isLoading = true;
  String _filterType = 'All'; // All | Sale | SaleReturn
  String _sortBy = 'Newest'; // Newest | Oldest | Highest | Lowest
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadSales();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final data = await SaleService.instance.getAllSalesHistory();
      if (!mounted) return;
      setState(() {
        _all = data;
        _isLoading = false;
      });
      _applyFilter();
      _fadeCtrl.forward(from: 0);
    } catch (e, st) {
      debugPrint('SalesHistory load error: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Failed to load: $e', AppColors.danger);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Purchase> list = _all.where((r) {
      final typeMatch = _filterType == 'All' || r.type == _filterType;
      final searchMatch =
          q.isEmpty ||
          r.referenceNo.toLowerCase().contains(q) ||
          (r.note?.toLowerCase().contains(q) ?? false) ||
          (r.paymentMethod?.toLowerCase().contains(q) ?? false);
      return typeMatch && searchMatch;
    }).toList();

    list.sort((a, b) {
      switch (_sortBy) {
        case 'Oldest':
          return a.purchaseDate.compareTo(b.purchaseDate);
        case 'Highest':
          return b.grandTotal.compareTo(a.grandTotal);
        case 'Lowest':
          return a.grandTotal.compareTo(b.grandTotal);
        default: // Newest
          return b.purchaseDate.compareTo(a.purchaseDate);
      }
    });

    setState(() => _filtered = list);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Derived Stats ────────────────────────────────────────────────────────
  int get _totalSalesCount => _all.where((r) => r.type == 'Sale').length;
  int get _totalReturnsCount =>
      _all.where((r) => r.type == 'SaleReturn').length;
  double get _totalRevenue =>
      _all.where((r) => r.type == 'Sale').fold(0.0, (s, r) => s + r.grandTotal);
  double get _netRevenue =>
      _all
          .where((r) => r.type == 'Sale')
          .fold(0.0, (s, r) => s + r.grandTotal) -
      _all
          .where((r) => r.type == 'SaleReturn')
          .fold(0.0, (s, r) => s + r.grandTotal);

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isWide),
            if (!_isLoading && _all.isNotEmpty)
              _buildStatStrip(currency, isWide),
            _buildToolbar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _SaleCard(
                          sale: _filtered[i],
                          currency: currency,
                          onTap: () => _showDetail(_filtered[i], currency),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isWide) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textMain,
                  size: 18,
                ),
              ),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  '${_filtered.length} record${_filtered.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _loadSales,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // POS shortcut
          GestureDetector(
            onTap: () => widget.onRouteSelected(AppRoutes.pos),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Open POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Strip ──────────────────────────────────────────────────────────
  Widget _buildStatStrip(String currency, bool isWide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: isWide
          ? Row(
              children: [
                _StatCard(
                  label: 'Total Sales',
                  value: '$_totalSalesCount',
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Returns',
                  value: '$_totalReturnsCount',
                  icon: Icons.replay_rounded,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Gross Revenue',
                  value: '$currency${_formatNum(_totalRevenue)}',
                  icon: Icons.attach_money_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Net Revenue',
                  value: '$currency${_formatNum(_netRevenue)}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.info,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StatCard(
                      label: 'Total Sales',
                      value: '$_totalSalesCount',
                      icon: Icons.shopping_bag_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Returns',
                      value: '$_totalReturnsCount',
                      icon: Icons.replay_rounded,
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      label: 'Gross Revenue',
                      value: '$currency${_formatNum(_totalRevenue)}',
                      icon: Icons.attach_money_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Net Revenue',
                      value: '$currency${_formatNum(_netRevenue)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ─── Toolbar ─────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by reference, note or payment…',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips + sort
          Row(
            children: [
              // Type filter chips
              _FilterChip(
                label: 'All',
                selected: _filterType == 'All',
                onTap: () {
                  setState(() => _filterType = 'All');
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sales',
                color: AppColors.success,
                selected: _filterType == 'Sale',
                onTap: () {
                  setState(() => _filterType = 'Sale');
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Returns',
                color: AppColors.purple,
                selected: _filterType == 'SaleReturn',
                onTap: () {
                  setState(() => _filterType = 'SaleReturn');
                  _applyFilter();
                },
              ),
              const Spacer(),
              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                      DropdownMenuItem(
                        value: 'Highest',
                        child: Text('Highest'),
                      ),
                      DropdownMenuItem(value: 'Lowest', child: Text('Lowest')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _sortBy = v);
                        _applyFilter();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No records found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty || _filterType != 'All'
                  ? 'Try adjusting your search or filter.'
                  : 'Completed sales will appear here.\nStart by processing a sale from the POS screen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            if (_searchCtrl.text.isEmpty && _filterType == 'All') ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => widget.onRouteSelected(AppRoutes.pos),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Go to POS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Detail Bottom Sheet ──────────────────────────────────────────────────
  void _showDetail(Purchase sale, String currency) async {
    // Fetch full order with items
    Purchase? detail;
    if (sale.id != null) {
      try {
        if (sale.type == 'Sale') {
          detail = await SaleService.instance.getById(sale.id!);
        } else {
          detail = await PurchaseService.instance.getById(sale.id!);
        }
      } catch (_) {}
    }
    if (!mounted) return;

    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        sale: detail ?? sale,
        currency: currency,
        dateFormatter: fmt,
      ),
    );
  }

  String _formatNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sale Card
// ────────────────────────────────────────────────────────────────────────────
class _SaleCard extends StatelessWidget {
  final Purchase sale;
  final String currency;
  final VoidCallback onTap;

  const _SaleCard({
    required this.sale,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = sale.type == 'Sale';
    final typeColor = isSale ? AppColors.success : AppColors.purple;
    final typeLabel = isSale ? 'Sale' : 'Return';
    final dateStr = DateFormat('dd MMM yy').format(sale.purchaseDate);
    final timeStr = DateFormat('hh:mm a').format(sale.purchaseDate);

    Color payColor;
    if (sale.paymentStatus == 'Paid') {
      payColor = AppColors.success;
    } else if (sale.paymentStatus == 'Partial') {
      payColor = AppColors.warning;
    } else {
      payColor = AppColors.danger;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSale ? Icons.shopping_bag_rounded : Icons.replay_rounded,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sale.referenceNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: typeLabel, color: typeColor),
                      const SizedBox(width: 6),
                      _Badge(label: sale.paymentStatus, color: payColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr · $timeStr${sale.paymentMethod != null ? ' · ${sale.paymentMethod}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + arrow
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${sale.grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSale ? AppColors.textMain : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.border,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Detail Bottom Sheet
// ────────────────────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final Purchase sale;
  final String currency;
  final DateFormat dateFormatter;

  const _DetailSheet({
    required this.sale,
    required this.currency,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = sale.type == 'Sale';
    final typeColor = isSale ? AppColors.success : AppColors.purple;
    final typeLabel = isSale ? 'Sale' : 'Return';

    Color payColor;
    if (sale.paymentStatus == 'Paid') {
      payColor = AppColors.success;
    } else if (sale.paymentStatus == 'Partial') {
      payColor = AppColors.warning;
    } else {
      payColor = AppColors.danger;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSale
                          ? Icons.shopping_bag_rounded
                          : Icons.replay_rounded,
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sale.referenceNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(label: typeLabel, color: typeColor),
                          ],
                        ),
                        Text(
                          dateFormatter.format(sale.purchaseDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Payment info row
                  Row(
                    children: [
                      _InfoTile(
                        label: 'Payment',
                        value: sale.paymentMethod ?? 'N/A',
                        icon: Icons.credit_card_rounded,
                      ),
                      const SizedBox(width: 12),
                      _InfoTile(
                        label: 'Status',
                        value: sale.paymentStatus,
                        valueColor: payColor,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 12),
                      _InfoTile(
                        label: 'Customer',
                        value: sale.customerId != null
                            ? '#${sale.customerId}'
                            : 'Walk-in',
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Items section
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (sale.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No item details available.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...sale.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.product?.name ??
                                    'Product #${item.productId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity} × $currency${item.unitCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$currency${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _TotalRow(
                          label: 'Subtotal',
                          value:
                              '$currency${sale.grandTotal.toStringAsFixed(2)}',
                        ),
                        if (sale.dueAmount > 0) ...[
                          const Divider(color: AppColors.border, height: 20),
                          _TotalRow(
                            label: 'Paid',
                            value:
                                '$currency${sale.paidAmount.toStringAsFixed(2)}',
                          ),
                          _TotalRow(
                            label: 'Due',
                            value:
                                '$currency${sale.dueAmount.toStringAsFixed(2)}',
                            valueColor: AppColors.danger,
                          ),
                        ],
                        const Divider(color: AppColors.border, height: 20),
                        _TotalRow(
                          label: 'Grand Total',
                          value:
                              '$currency${sale.grandTotal.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  if (sale.note != null && sale.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sale.note!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMain,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => PdfExportHelper.exportPurchaseDetail(sale),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                          label: const Text('PDF Invoice'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ExcelExportHelper.exportPurchaseDetail(sale),
                          icon: const Icon(Icons.grid_on, color: Colors.green, size: 18),
                          label: const Text('Excel Invoice'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textMain : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
