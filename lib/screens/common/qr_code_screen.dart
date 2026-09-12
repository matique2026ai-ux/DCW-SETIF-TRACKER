import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:drh_setif_tracker/utils/theme.dart';

class QRCodeScreen extends StatelessWidget {
  final String data;
  final String title;
  final String subtitle;

  const QRCodeScreen({
    super.key,
    required this.data,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.BackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF2D1035),
        title: Text(
          title,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.AccentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.CardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.BorderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.BackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: AppTheme.TextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'امسح الرمز للتحقق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: AppTheme.AccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required Map<String, dynamic> record,
    required String title,
  }) {
    final qrData = jsonEncode({
      'type': record['type'] ?? 'attendance',
      'employee': record['employeeName'] ?? '',
      'date': record['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      'time': record['time'] ?? DateTime.now().toString().substring(11, 19),
      'lat': record['latitude'],
      'lng': record['longitude'],
      'id': record['id'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRCodeScreen(
          data: qrData,
          title: title,
          subtitle:
              '${record['employeeName'] ?? ''} • ${record['date'] ?? ''} • ${record['time'] ?? ''}',
        ),
      ),
    );
  }
}
