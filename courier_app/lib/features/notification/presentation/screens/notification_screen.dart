import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/push_notification_sender.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isSending = false;
  String? _selectedUserId;
  String? _selectedUserName;
  List<Map<String, String>> _userList = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadUsers());
  }

  Future<void> _loadUsers() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      // Ambil semua customer dari orders dan courier sendiri
      final courier = ref.read(authStateProvider).courier;
      final List<Map<String, String>> users = [];

      // Ambil dari orders collection — customer yang pernah order
      if (courier != null) {
        final orderRepo = ref.read(orderRepositoryProvider);
        final myOrders = await orderRepo.getMyOrders(courier.id);
        final seen = <String>{};
        for (final o in myOrders) {
          if (o.userId.isNotEmpty && !seen.contains(o.userId)) {
            seen.add(o.userId);
            // Coba dapetin nama customer
            try {
              final userDoc = await dbService.getUserById(o.userId);
              final name = userDoc?['name'] ?? 'Customer #${o.userId.substring(0, 6)}';
              users.add({'id': o.userId, 'name': name});
            } catch (_) {
              users.add({'id': o.userId, 'name': 'Customer #${o.userId.substring(0, 6)}'});
            }
          }
        }
      }

      // Ambil juga dari users collection (3 aja)
      try {
        final usersRes = await dbService.listUsers();
        for (final u in usersRes) {
          final uid = u['\$id'] ?? '';
          if (uid.isNotEmpty && !users.any((x) => x['id'] == uid)) {
            users.add({'id': uid, 'name': u['name'] ?? u['email'] ?? uid});
          }
        }
      } catch (_) {}

      if (mounted) setState(() => _userList = users);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final courier = ref.read(authStateProvider).courier;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, size: 22),
              tooltip: 'Tandai semua dibaca',
              onPressed: () {
                if (courier != null) {
                  ref.read(notificationsProvider.notifier).markAllAsRead(courier.id);
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (courier != null) {
            ref.read(notificationsProvider.notifier).loadNotifications(courier.id);
          }
        },
        child: notifications.isEmpty
            ? _buildEmptyState()
            : _buildNotificationList(notifications),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }

  void _showSendDialog() {
    _selectedUserId = null;
    _selectedUserName = null;
    _titleCtrl.clear();
    _bodyCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Kirim Notifikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                decoration: InputDecoration(
                  labelText: 'Penerima',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                hint: const Text('Pilih user/courier'),
                isExpanded: true,
                items: _userList.map((u) {
                  return DropdownMenuItem(
                    value: u['id'],
                    child: Text(u['name']!, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedUserId = val;
                    _selectedUserName = _userList.firstWhere((u) => u['id'] == val)['name'];
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Isi Pesan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : () => _sendNotif(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendNotif(BuildContext ctx) async {
    final userId = _selectedUserId;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (userId == null || title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    setState(() => _isSending = true);

    try {
      final sender = ref.read(pushNotificationSenderProvider);
      await sender.sendToUser(userId: userId, title: title, body: body, category: 'Pesan');

      if (!context.mounted) return;
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi terkirim!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async {
        final courier = ref.read(authStateProvider).courier;
        if (courier != null) {
          ref.read(notificationsProvider.notifier).loadNotifications(courier.id);
        }
      },
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 72,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
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

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return _buildNotificationCard(notif);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    IconData icon;
    Color color;
    switch (notif.category) {
      case 'Pesanan':
        icon = Icons.shopping_bag_outlined;
        color = AppColors.primary;
        break;
      case 'Promo & Info':
        icon = Icons.discount_outlined;
        color = Colors.orange;
        break;
      case 'Sistem & Akun':
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.textSecondary;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: notif.isRead ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(notif.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notif.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.3),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notif.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        if (notif.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notif.category,
                              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
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
}
