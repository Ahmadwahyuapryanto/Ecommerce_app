// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

// Enum baru untuk status filter
enum NotificationFilter { semua, belumDibaca, sudahDibaca }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // State untuk melacak filter yang aktif
  NotificationFilter _selectedFilter = NotificationFilter.semua;

  // --- DATA DUMMY (Contoh) ---
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Diskon Spesial 50%!',
      body: 'Dapatkan diskon spesial untuk semua produk elektronik. Hanya hari ini!',
      type: NotificationType.promo,
      createdAt: DateTime.now(),
    ),
    AppNotification(
      id: '2',
      title: 'Pesanan Dikirim',
      body: 'Pesanan Anda #1751613082540 telah dikirim dan sedang dalam perjalanan.',
      type: NotificationType.orderStatus,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: '3',
      title: 'Pesanan Selesai',
      body: 'Pesanan Anda #1751552452250 telah sampai. Jangan lupa beri ulasan!',
      type: NotificationType.orderStatus,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: '5',
      title: 'Promo Gajian!',
      body: 'Nikmati cashback hingga 20% untuk semua metode pembayaran. S&K berlaku.',
      type: NotificationType.promo,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppNotification(
      id: '4',
      title: 'Selamat Datang di KEYWORD!',
      body: 'Jelajahi ribuan produk terbaik dan nikmati pengalaman belanja Anda.',
      type: NotificationType.general,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      isRead: true,
    ),
  ];

  Map<String, List<AppNotification>> _groupAndFilterNotifications() {
    List<AppNotification> filteredNotifications;

    // Langkah 1: Filter notifikasi berdasarkan status yang dipilih
    switch (_selectedFilter) {
      case NotificationFilter.belumDibaca:
        filteredNotifications = _notifications.where((n) => !n.isRead).toList();
        break;
      case NotificationFilter.sudahDibaca:
        filteredNotifications = _notifications.where((n) => n.isRead).toList();
        break;
      case NotificationFilter.semua:
      default:
        filteredNotifications = _notifications;
        break;
    }

    // Langkah 2: Kelompokkan notifikasi yang sudah difilter
    final Map<String, List<AppNotification>> grouped = {};
    for (var notif in filteredNotifications) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final notificationDate = DateTime(notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);

      String groupKey;
      if (notificationDate == today) {
        groupKey = 'Hari Ini';
      } else if (today.difference(notificationDate).inDays < 7) {
        groupKey = 'Minggu Ini';
      } else {
        groupKey = 'Lebih Lama';
      }

      if (grouped[groupKey] == null) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(notif);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupAndFilterNotifications();
    final groupKeys = groupedNotifications.keys.toList();

    return Scaffold(
      body: Column(
        children: [
          // --- WIDGET FILTER BARU ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip(NotificationFilter.semua, 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip(NotificationFilter.belumDibaca, 'Belum Dibaca'),
                const SizedBox(width: 8),
                _buildFilterChip(NotificationFilter.sudahDibaca, 'Sudah Dibaca'),
              ],
            ),
          ),
          const Divider(height: 1),
          // --- DAFTAR NOTIFIKASI ---
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: groupKeys.length,
              itemBuilder: (context, index) {
                final groupName = groupKeys[index];
                final notificationsInGroup = groupedNotifications[groupName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER GRUP YANG DIPERBARUI ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 14, // Ukuran font lebih kecil
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600, // Warna abu-abu
                        ),
                      ),
                    ),
                    ...notificationsInGroup.map((notif) {
                      return _buildNotificationCard(notif);
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat chip filter
  Widget _buildFilterChip(NotificationFilter filter, String label) {
    final bool isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return InkWell(
      onTap: () {
        setState(() {
          notification.isRead = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: notification.isRead ? 0 : 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12, top: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Icon(notification.icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMM yyyy, HH:mm').format(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Notifikasi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua pemberitahuan baru akan muncul di sini.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}