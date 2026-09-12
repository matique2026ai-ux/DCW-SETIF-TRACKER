import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';

class InspectorScreen extends StatefulWidget {
  const InspectorScreen({super.key});

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  bool _isCheckedIn = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentAttendance;
  String? _checkInTime;
  List<Map<String, dynamic>> _todayVisits = [];
  int _visitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final api = context.read<AuthService>().api;
      final att = await api.getTodayAttendance();
      final visits = await api.getTodayVisits();
      if (mounted) {
        setState(() {
          if (att != null && att['Id'] != null) {
            _isCheckedIn = true;
            _currentAttendance = att;
            _checkInTime = att['CheckInTime'].toString().substring(11, 16);
          }
          _todayVisits = visits;
          _visitCount = visits.length;
        });
      }
    } catch (e) {}
  }

  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 600,
      );
      if (photo == null) return null;
      final bytes = await File(photo.path).readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkIn() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    final pos = await _getPosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.isArabic ? 'فعّل خدمة الموقع' : 'Activez la localisation',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: AppTheme.WarningColor,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final photo = await _takePhoto();
    if (photo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.isArabic ? 'التقط صورة أولاً' : 'Prenez une photo d\'abord',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: AppTheme.WarningColor,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;
      await api.checkIn(
        user!.employeeId!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        photo: photo,
      );
      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = DateTime.now().toString().substring(11, 16);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅'), backgroundColor: AppTheme.SuccessColor),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.DangerColor),
        );
      }
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isLoading = true);
    final pos = await _getPosition();
    if (pos == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;
      await api.checkOut(
        user!.employeeId!,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (mounted) {
        setState(() {
          _isCheckedIn = false;
          _checkInTime = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅'), backgroundColor: AppTheme.SuccessColor),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVisit() async {
    final loc = AppLocalizations.of(context);
    final pos = await _getPosition();
    if (pos == null) return;

    final photo = await _takePhoto();
    if (photo == null) return;

    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.recordVisit,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.SuccessColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.SuccessColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: AppTheme.SuccessColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: loc.shopName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: loc.notes,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel, style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = context.read<AuthService>().api;
                final user = context.read<AuthService>().currentUser;
                await api.recordVisit(
                  employeeId: user!.employeeId!,
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  photo: photo,
                  shopName: nameCtrl.text,
                  notes: notesCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅'),
                    backgroundColor: AppTheme.SuccessColor,
                  ),
                );
                _loadStatus();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'),
                    backgroundColor: AppTheme.DangerColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.SuccessColor,
            ),
            child: Text(loc.save, style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = context.watch<AuthService>().currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: Color(0xFF2D1035),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.explore, size: 18, color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text(
                loc.isArabic ? 'التفتيش الميداني' : 'Contrôle Terrain',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.language, color: Color(0xFFD4AF37)),
              onPressed: () =>
                  context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white70),
              onPressed: () {
                context.read<AuthService>().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF881337), Color(0xFF4C0519)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.AccentColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF881337).withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                        ),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 26),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.fullName ?? ''}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            loc.roleInspector,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isCheckedIn
                            ? AppTheme.SuccessColor
                            : AppTheme.WarningColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isCheckedIn ? loc.checkedIn : loc.notCheckedIn,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Attendance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.CardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.BorderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.AccentColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          loc.attendance,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    if (_isCheckedIn) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.SuccessColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.SuccessColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.SuccessColor,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              loc.checkedIn,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppTheme.SuccessColor,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '$_checkInTime',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppTheme.SuccessColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkOut,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.exit_to_app),
                          label: Text(
                            loc.checkOut,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.WarningColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 56,
                              color: AppTheme.TextSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              loc.notCheckedIn,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: AppTheme.TextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkIn,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.fingerprint),
                          label: Text(
                            _isLoading
                                ? loc.checkInProgress
                                : loc.checkInWithCamera,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.AccentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Visit Button
              if (_isCheckedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _recordVisit,
                    icon: Icon(Icons.store),
                    label: Text(
                      loc.recordVisit,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.PrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Today's visits
                Row(
                  children: [
                    Icon(Icons.history, color: AppTheme.AccentColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '${loc.visitsToday} ($_visitCount)',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (_todayVisits.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.CardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.BorderColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        loc.noVisits,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ..._todayVisits.map(
                    (v) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.CardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.BorderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.SuccessColor.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.store,
                              color: AppTheme.SuccessColor,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v['ShopName'] ?? (loc.isArabic ? 'زيارة' : 'Visite')}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${v['LocationName'] ?? ''} • ${v['CreatedAt'].toString().substring(11, 16)}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.SuccessColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
