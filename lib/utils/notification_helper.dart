import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';

// Enum untuk menentukan jenis notifikasi
enum NotificationType { success, error, info }

class NotificationHelper {
  static void show(
      BuildContext context, {
        required String message,
        NotificationType type = NotificationType.info,
      }) {
    // Menentukan warna dan ikon berdasarkan jenis notifikasi
    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green.shade600;
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red.shade600;
        iconData = Icons.error_outline;
        break;
      case NotificationType.info:
      default:
        backgroundColor = Colors.blue.shade600;
        iconData = Icons.info_outline;
        break;
    }

    // Menampilkan notifikasi menggunakan package Flash
    context.showFlash<bool>(
      barrierColor: Colors.black.withOpacity(0.1),
      barrierDismissible: true,
      duration: const Duration(seconds: 3),
      builder: (context, controller) {
        return FlashBar(
          controller: controller,
          clipBehavior: Clip.antiAlias,
          indicatorColor: Colors.white.withOpacity(0.8),
          position: FlashPosition.top, // Muncul dari atas
          backgroundColor: backgroundColor,
          // Gaya visual notifikasi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: const EdgeInsets.all(16.0),
          // Konten notifikasi
          content: Row(
            children: [
              Icon(iconData, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}