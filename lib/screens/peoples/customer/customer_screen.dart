import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/customer.dart';
import 'package:ims_pos_system/services/customer_service.dart';

class CustomerScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final Map<String, dynamic>? args;

  const CustomerScreen({super.key, required this.onRouteSelected, this.args});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;
  final Set<int> _hoveredRows = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await CustomerService.instance.getAll();
      if (mounted) {
        setState(() {
          _customers = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _customers
          : _customers.where((c) {
              return c.name.toLowerCase().contains(q) ||
                  (c.code?.toLowerCase().contains(q) ?? false) ||
                  (c.email?.toLowerCase().contains(q) ?? false) ||
                  (c.phone?.contains(q) ?? false);
            }).toList();
    });
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CustomerService.instance.delete(customer.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${customer.name}" deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadCustomers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Customers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_customers.length} customers total',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          widget.onRouteSelected(AppRoutes.createCustomer),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Customers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_customers.length} customers total',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        widget.onRouteSelected(AppRoutes.createCustomer),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),
        SizedBox(
          height: 42,
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Search customers by name, code, email or phone...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? _buildEmpty()
              : (isMobile ? _buildCardList() : _buildTable()),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 52,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'No results for "${_searchController.text}"'
                : 'No customers yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different keyword.'
                : 'Click "Create Customer" to get started.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: _headerCell('Name')),
              Expanded(flex: 1, child: _headerCell('Code')),
              Expanded(flex: 2, child: _headerCell('Email')),
              Expanded(flex: 1, child: _headerCell('Phone')),
              Expanded(flex: 1, child: _headerCell('Points')),
              Expanded(flex: 1, child: _headerCell('Status')),
              SizedBox(width: 80, child: _headerCell('Actions')),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: _loadCustomers,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _filtered.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, index) => _buildRow(_filtered[index], index),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCardList() {
    return Column(
      children: _filtered.map((customer) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              customer.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (customer.email != null)
                  Text(
                    customer.email!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.info,
                  tooltip: 'Edit',
                  onPressed: () {
                    if (customer.id != null) {
                      widget.onRouteSelected(
                        '${AppRoutes.editCustomer}/${customer.id}',
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  tooltip: 'Delete',
                  onPressed: () => _deleteCustomer(customer),
                ),
              ],
            ),
            onTap: () {
              if (customer.id != null) {
                widget.onRouteSelected(
                  '${AppRoutes.editCustomer}/${customer.id}',
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRow(Customer customer, int index) {
    final isHovered = _hoveredRows.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(index)),
      onExit: (_) => setState(() => _hoveredRows.remove(index)),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (customer.id != null) {
            widget.onRouteSelected('${AppRoutes.editCustomer}/${customer.id}');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: isHovered ? AppColors.background.withAlpha(40) : Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  customer.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  customer.code ?? '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  customer.email ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  customer.phone ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  customer.loyaltyPoints.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: customer.isActive
                        ? AppColors.successLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customer.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      tooltip: 'Edit',
                      onTap: () => widget.onRouteSelected(
                        '${AppRoutes.editCustomer}/${customer.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: () => _deleteCustomer(customer),
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

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
