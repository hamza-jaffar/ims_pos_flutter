import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/user.dart';
import 'package:ims_pos_system/services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const UserManagementScreen({super.key, required this.onRouteSelected});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await UserService.instance.getAllUsers();
    if (mounted)
      setState(() {
        _users = users;
        _isLoading = false;
      });
  }

  List<User> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Create user dialog ──────────────────────────────────────
  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: _dialogTitle(Icons.person_add_outlined, 'Create New User'),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    nameCtrl,
                    'Full Name',
                    Icons.person_outline,
                    required: true,
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    emailCtrl,
                    'Email Address',
                    Icons.email_outlined,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      return emailRx.hasMatch(v.trim())
                          ? null
                          : 'Enter a valid email.';
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    passCtrl,
                    'Password',
                    Icons.lock_outline,
                    required: true,
                    obscure: obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setDState(() => obscure = !obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Password is required.';
                      if (v.length < 6) return 'Min 6 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    confirmCtrl,
                    'Confirm Password',
                    Icons.lock_outline,
                    required: true,
                    obscure: obscure,
                    validator: (v) {
                      if (v != passCtrl.text) return 'Passwords do not match.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Check email duplication
                final exists = await UserService.instance.emailExists(
                  emailCtrl.text.trim(),
                );
                if (exists) {
                  _showSnack('Email already in use.', AppColors.danger);
                  return;
                }

                try {
                  await UserService.instance.createUser(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    password: passCtrl.text,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _showSnack('User created successfully!', AppColors.success);
                  _loadUsers();
                } catch (e) {
                  _showSnack('Error: $e', AppColors.danger);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset password dialog ────────────────────────────────────
  void _showResetPasswordDialog(User user) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: _dialogTitle(Icons.lock_reset_outlined, 'Reset Password'),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _userAvatar(user, size: 36),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textMain,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dialogField(
                    passCtrl,
                    'New Password',
                    Icons.lock_outline,
                    required: true,
                    obscure: obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setDState(() => obscure = !obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Password is required.';
                      if (v.length < 6) return 'Min 6 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    confirmCtrl,
                    'Confirm Password',
                    Icons.lock_outline,
                    required: true,
                    obscure: obscure,
                    validator: (v) {
                      if (v != passCtrl.text) return 'Passwords do not match.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await UserService.instance.resetPassword(
                    userId: user.id!,
                    newPassword: passCtrl.text,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _showSnack('Password reset successfully!', AppColors.success);
                } catch (e) {
                  _showSnack('Error: $e', AppColors.danger);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ──────────────────────────────────────
  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: _dialogTitle(Icons.delete_outline, 'Delete User'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const TextSpan(
                text:
                    '? This action cannot be undone and all associated data will be removed.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UserService.instance.deleteUser(user.id!);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _showSnack(
                  '${user.name} deleted successfully.',
                  AppColors.success,
                );
                _loadUsers();
              } catch (e) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                _showSnack('$e', AppColors.danger);
              }
            },
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
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Page header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.manage_accounts_outlined,
                color: AppColors.purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage system users, passwords and access.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.person_add_rounded, size: 17),
              label: const Text(
                'Add User',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
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

        // Search + stats bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email…',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_users.length} user${_users.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Table card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : filtered.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _TableHeader('User')),
                          Expanded(flex: 3, child: _TableHeader('Email')),
                          Expanded(flex: 1, child: _TableHeader('Role')),
                          SizedBox(width: 100, child: _TableHeader('Actions')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    // Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) => _UserRow(
                        user: filtered[i],
                        onResetPassword: _showResetPasswordDialog,
                        onDelete: _confirmDelete,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _search.isEmpty ? 'No users found.' : 'No results for "$_search"',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog helpers ────────────────────────────────────────────
Widget _dialogTitle(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
    ],
  );
}

Widget _dialogField(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  bool required = false,
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
  Widget? suffixIcon,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
      const SizedBox(height: 7),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? 'This field is required.'
                      : null
                : null),
      ),
    ],
  );
}

// ── User avatar ───────────────────────────────────────────────
Widget _userAvatar(User user, {double size = 42}) {
  final initials = user.name
      .trim()
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  final colors = [
    AppColors.primary,
    AppColors.purple,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
  ];
  final color = colors[user.name.codeUnitAt(0) % colors.length];

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ),
  );
}

// ── Table header cell ─────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ── User table row ────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final User user;
  final ValueChanged<User> onResetPassword;
  final ValueChanged<User> onDelete;

  const _UserRow({
    required this.user,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.id == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // User name + avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _userAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Email
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Role badge
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAdmin ? AppColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'User',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reset password
                Tooltip(
                  message: 'Reset Password',
                  child: InkWell(
                    onTap: () => onResetPassword(user),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.lock_reset_outlined,
                        size: 17,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Delete
                if (!isAdmin)
                  Tooltip(
                    message: 'Delete User',
                    child: InkWell(
                      onTap: () => onDelete(user),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
