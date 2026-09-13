import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/utils/constants.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/common/qr_code_screen.dart';

class InspectorScreen extends StatefulWidget {
  const InspectorScreen({super.key});

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  bool _isCheckedIn = false;
  bool _isLoading = false;
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
            _checkInTime = att['CheckInTime'].toString().substring(11, 16);
          }
          _todayVisits = visits;
          _visitCount = visits.length;
        });
      }
    } catch (_) {
      // Load error ignored on initial status check
    }
  }

  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      return pos;
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
      final bytes = await photo.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkIn() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    Position? pos = await _getPosition();
    pos ??= Position(
      latitude: AppConstants.hqLatitude,
      longitude: AppConstants.hqLongitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    final photo = await _takePhoto();

    if (!mounted) return;

    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;

      final isAtHQ = AppConstants.isWithinHQ(pos.latitude, pos.longitude);
      final distance = AppConstants.distanceBetween(
        pos.latitude,
        pos.longitude,
        AppConstants.hqLatitude,
        AppConstants.hqLongitude,
      );

      await api.checkIn(
        user!.employeeId!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        photo: photo,
        location: isAtHQ ? 'HQ' : 'Field',
      );
      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = DateTime.now().toString().substring(11, 16);
          _isLoading = false;
        });

        final message = isAtHQ
            ? (loc.isArabic
                  ? '✅ تم تسجيل الحضور من مقر المديرية'
                  : '✅ Présence enregistrée au siège')
            : (loc.isArabic
                  ? '⚠️ تم التسجيل خارج المقر (${distance.round()}م)'
                  : '⚠️ Enregistré hors siège (${distance.round()}m)');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: isAtHQ
                ? AppTheme.SuccessColor
                : AppTheme.WarningColor,
            duration: const Duration(seconds: 3),
          ),
        );
        if (mounted) {
          QRCodeScreen.show(
            context,
            record: {
              'type': 'checkin',
              'employeeName':
                  context.read<AuthService>().currentUser?.fullName ?? '',
              'date': DateTime.now().toString().split(' ')[0],
              'time': DateTime.now().toString().substring(11, 19),
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'id': DateTime.now().millisecondsSinceEpoch,
            },
            title: 'إثبات الحضور',
          );
        }
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
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    Position? pos = await _getPosition();
    pos ??= Position(
      latitude: AppConstants.hqLatitude,
      longitude: AppConstants.hqLongitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    if (!mounted) return;

    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;
      final isAtHQ = AppConstants.isWithinHQ(pos.latitude, pos.longitude);
      final distance = AppConstants.distanceBetween(
        pos.latitude,
        pos.longitude,
        AppConstants.hqLatitude,
        AppConstants.hqLongitude,
      );

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

        final message = isAtHQ
            ? (loc.isArabic ? '✅ تم الانصراف من المقر' : '✅ Départ du siège')
            : (loc.isArabic
                  ? '✅ تم الانصراف من مكان العمل (${distance.round()}م عن المقر)'
                  : '✅ Départ du lieu de travail (${distance.round()}m du siège)');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.SuccessColor,
            duration: const Duration(seconds: 3),
          ),
        );

        QRCodeScreen.show(
          context,
          record: {
            'type': 'checkout',
            'employeeName':
                context.read<AuthService>().currentUser?.fullName ?? '',
            'date': DateTime.now().toString().split(' ')[0],
            'time': DateTime.now().toString().substring(11, 19),
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'id': DateTime.now().millisecondsSinceEpoch,
          },
          title: 'إثبات الانصراف',
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

  Future<void> _recordVisit() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    Position? pos = await _getPosition();
    pos ??= Position(
      latitude: AppConstants.hqLatitude,
      longitude: AppConstants.hqLongitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    final photo = await _takePhoto();
    setState(() => _isLoading = false);
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
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.SuccessColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.SuccessColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: AppTheme.SuccessColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
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
            child: Text(loc.cancel, style: const TextStyle(fontFamily: 'Tajawal')),
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
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅'),
                    backgroundColor: AppTheme.SuccessColor,
                  ),
                );
                _loadStatus();
                QRCodeScreen.show(
                  context,
                  record: {
                    'type': 'visit',
                    'employeeName':
                        context.read<AuthService>().currentUser?.fullName ??
                        '',
                    'date': DateTime.now().toString().split(' ')[0],
                    'time': DateTime.now().toString().substring(11, 19),
                    'latitude': pos.latitude,
                    'longitude': pos.longitude,
                    'id': DateTime.now().millisecondsSinceEpoch,
                  },
                  title: 'إثبات الزيارة',
                );
              } catch (e) {
                if (!mounted) return;
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
            child: Text(loc.save, style: const TextStyle(fontFamily: 'Tajawal')),
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
          backgroundColor: const Color(0xFF2D1035),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.explore, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.isArabic ? 'التفتيش الميداني' : 'Contrôle Terrain',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Color(0xFFD4AF37)),
              onPressed: () =>
                  context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () {
                context.read<AuthService>().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF881337), Color(0xFF4C0519)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.AccentColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF881337).withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.roleInspector,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
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
                        style: const TextStyle(
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
              const SizedBox(height: 20),

              // Attendance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.AccentColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loc.attendance,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_isCheckedIn) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.SuccessColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.SuccessColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.SuccessColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.checkedIn,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppTheme.SuccessColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_checkInTime',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: AppTheme.SuccessColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkOut,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.exit_to_app),
                          label: Text(
                            loc.checkOut,
                            style: const TextStyle(
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
                            const SizedBox(height: 10),
                            Text(
                              loc.notCheckedIn,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: AppTheme.TextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkIn,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.fingerprint),
                          label: Text(
                            _isLoading
                                ? loc.checkInProgress
                                : loc.checkInWithCamera,
                            style: const TextStyle(
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
              const SizedBox(height: 16),

              // Visit Button
              if (_isCheckedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _recordVisit,
                    icon: const Icon(Icons.store),
                    label: Text(
                      loc.recordVisit,
                      style: const TextStyle(
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
                const SizedBox(height: 20),

                // Today's visits
                Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.AccentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${loc.visitsToday} ($_visitCount)',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_todayVisits.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
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
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ..._todayVisits.map(
                    (v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
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
                            child: const Icon(
                              Icons.store,
                              color: AppTheme.SuccessColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v['ShopName'] ?? (loc.isArabic ? 'زيارة' : 'Visite')}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${v['LocationName'] ?? ''} • ${v['CreatedAt'].toString().substring(11, 16)}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
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
