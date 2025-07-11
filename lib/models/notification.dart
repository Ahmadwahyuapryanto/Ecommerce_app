// lib/models/notification.dart

import 'package:flutter/material.dart';

// Enum untuk tipe notifikasi agar lebih terstruktur
enum NotificationType { promo, orderStatus, general }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  // Helper untuk mendapatkan ikon berdasarkan tipe notifikasi
  IconData get icon {
    switch (type) {
      case NotificationType.promo:
        return Icons.campaign_outlined;
      case NotificationType.orderStatus:
        return Icons.local_shipping_outlined;
      case NotificationType.general:
      default:
        return Icons.notifications_outlined;
    }
  }
}