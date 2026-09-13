import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/services/offline_sync_service.dart';
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
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  String? _checkInTime;
  String? _checkInPhoto;
  double? _checkInLat;
  double? _checkInLng;
  List<Map<String, dynamic>> _todayVisits = [];
  int _visitCount = 0;
  Map<String, dynamic>? _activeProgram;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadActiveProgram();
  }

  String _formatTime(dynamic val) {
    if (val == null) return '';
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return '';
    try {
      if (str.contains('T')) {
        final timePart = str.split('T')[1];
        if (timePart.length >= 5) return timePart.substring(0, 5);
      }
      if (str.contains(' ')) {
        final parts = str.split(' ');
        if (parts.length > 1 && parts[1].length >= 5) {
          return parts[1].substring(0, 5);
        }
      }
      if (str.length >= 5) return str.substring(0, 5);
    } catch (_) {}
    return str;
  }

  Future<void> _loadActiveProgram() async {
    try {
      final api = context.read<AuthService>().api;
      final progs = await api.getPrograms();
      if (progs.isNotEmpty && mounted) {
        setState(() {
          _activeProgram = progs.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStatus() async {
    final pending = await OfflineSyncService.getPendingCount();
    if (mounted) {
      setState(() => _pendingSyncCount = pending);
    }

    try {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      final api = auth.api;
      final empId = auth.currentUser?.employeeId ?? auth.currentUser?.id ?? 1;
      final att = await api.getTodayAttendance();
      final visits = await api.getTodayVisits(empId);
      final offlineVisits = await OfflineSyncService.getCachedVisits();

      if (mounted) {
        setState(() {
          if (att != null && att['Id'] != null) {
            _isCheckedIn = true;
            _checkInTime = _formatTime(att['CheckInTime']);
            _checkInPhoto = att['CheckInPhoto']?.toString();
            _checkInLat = att['CheckInLatitude'] != null
                ? double.tryParse(att['CheckInLatitude'].toString())
                : null;
            _checkInLng = att['CheckInLongitude'] != null
                ? double.tryParse(att['CheckInLongitude'].toString())
                : null;
          }
          _todayVisits = [...offlineVisits, ...visits];
          _visitCount = _todayVisits.length;
        });
      }

      if (pending > 0) {
        _syncPendingItems(silent: true);
      }
    } catch (_) {
      final cachedAtt = await OfflineSyncService.getCachedAttendance();
      final cachedVisits = await OfflineSyncService.getCachedVisits();
      if (mounted) {
        setState(() {
          if (cachedAtt != null) {
            _isCheckedIn = cachedAtt['isCheckedIn'] == true;
            _checkInTime = cachedAtt['checkInTime']?.toString();
            _checkInPhoto = cachedAtt['photo']?.toString();
            _checkInLat = double.tryParse(cachedAtt['latitude']?.toString() ?? '');
            _checkInLng = double.tryParse(cachedAtt['longitude']?.toString() ?? '');
          }
          _todayVisits = cachedVisits;
          _visitCount = cachedVisits.length;
        });
      }
    }
  }

  Future<void> _syncPendingItems({bool silent = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final api = context.read<AuthService>().api;
      final result = await OfflineSyncService.syncAll(api);
      final int synced = (result['syncedCount'] as num?)?.toInt() ?? 0;
      final int remaining = await OfflineSyncService.getPendingCount();

      if (mounted) {
        setState(() {
          _pendingSyncCount = remaining;
          _isSyncing = false;
        });

        if (synced > 0) {
          _loadStatus();
        }

        if (!silent && mounted) {
          if (synced > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ تمت مزامنة $synced عمليات بنجاح مع السيرفر',
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: AppTheme.SuccessColor,
              ),
            );
          } else if (remaining > 0) {
            final List<dynamic> errors = (result['errors'] as List<dynamic>?) ?? [];
            final String errorMsg = errors.isNotEmpty
                ? errors.first.toString()
                : '⚠️ تعذر المزامنة: يرجى التحقق من اتصال السيرفر';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMsg,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: AppTheme.WarningColor,
                action: SnackBarAction(
                  label: 'مسح العالق',
                  textColor: Colors.white,
                  onPressed: () async {
                    await OfflineSyncService.clearAll();
                    if (mounted) {
                      setState(() => _pendingSyncCount = 0);
                      _loadStatus();
                    }
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: AppTheme.WarningColor,
            ),
          );
        }
      }
    }
  }

  Future<Position?> _getPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) return null;

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _pickPhoto({bool fromGallery = false}) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
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

    final photo = await _pickPhoto();

    if (!mounted) return;

    final user = context.read<AuthService>().currentUser;
    final int empId = user?.employeeId ?? user?.id ?? 1;
    final isAtHQ = AppConstants.isWithinHQ(pos.latitude, pos.longitude);
    final distance = AppConstants.distanceBetween(
      pos.latitude,
      pos.longitude,
      AppConstants.hqLatitude,
      AppConstants.hqLongitude,
    );

    final nowStr = DateTime.now().toString().substring(11, 16);
    final payload = {
      'employeeId': empId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'photo': photo,
      'location': isAtHQ ? 'HQ' : 'Field',
    };

    bool isOfflineMode = false;

    try {
      final api = context.read<AuthService>().api;
      await api.checkIn(
        empId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        photo: photo,
        location: isAtHQ ? 'HQ' : 'Field',
      );
    } catch (e) {
      isOfflineMode = true;
      await OfflineSyncService.queueCheckIn(payload);
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pending = await OfflineSyncService.getPendingCount();

    if (mounted) {
      setState(() {
        _isCheckedIn = true;
        _checkInTime = nowStr;
        _checkInPhoto = photo;
        _checkInLat = pos?.latitude;
        _checkInLng = pos?.longitude;
        _isLoading = false;
        _pendingSyncCount = pending;
      });

      final message = isOfflineMode
          ? (loc.isArabic
              ? '📡 تم حفظ الحضور محلياً (بدون نت) — ستتم المزامنة تلقائياً'
              : '📡 Présence enregistrée hors ligne — synchro auto')
          : (isAtHQ
              ? (loc.isArabic
                  ? '✅ تم تسجيل الحضور من مقر المديرية'
                  : '✅ Présence enregistrée au siège')
              : (loc.isArabic
                  ? '⚠️ تم التسجيل خارج المقر (${distance.round()}م)'
                  : '⚠️ Enregistré hors siège (${distance.round()}m)'));

      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: isOfflineMode
              ? const Color(0xFFD97706)
              : (isAtHQ ? AppTheme.SuccessColor : AppTheme.WarningColor),
          duration: const Duration(seconds: 4),
        ),
      );

      _showAttendanceProof(isOffline: isOfflineMode);
    }
  }

  void _handleSmartCheckOut() {
    final now = DateTime.now();
    final bool isEarly = now.hour < 15 || (now.hour == 15 && now.minute < 30);

    if (isEarly) {
      _showEarlyCheckOutDialog();
    } else {
      _executeCheckOut(notes: null);
    }
  }

  void _showEarlyCheckOutDialog() {
    final reasonCtrl = TextEditingController();
    String selectedReason = 'مهمة تفتيشية خارجية مسائية';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.CardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.WarningColor, size: 24),
              SizedBox(width: 8),
              Text(
                'تنبيه الانصراف قبل الوقت',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.WarningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.WarningColor.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '⚠️ ينتهي الدوام الرسمي في الساعة 16:30. يتطلب الانصراف المبكر توثيق المبرر الإداري أو المهمة المكلف بها.',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFFFCD34D)),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'نوع المبرر الإداري:',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                dropdownColor: AppTheme.CardColor,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'مهمة تفتيشية خارجية مسائية', child: Text('مهمة تفتيشية خارجية مسائية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                  DropdownMenuItem(value: 'حالة اضطرارية شخصية / وعكة صحية', child: Text('حالة اضطرارية شخصية / وعكة صحية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                  DropdownMenuItem(value: 'إذن خروج رسمي من رئيس المصلحة', child: Text('إذن خروج رسمي من رئيس المصلحة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                  DropdownMenuItem(value: 'مرافقة لجنة ولائية مشتركة', child: Text('مرافقة لجنة ولائية مشتركة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'تفاصيل وملاحظات إضافية (اختياري)',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final fullReason = '$selectedReason ${reasonCtrl.text.trim().isNotEmpty ? "— ${reasonCtrl.text.trim()}" : ""}';
                Navigator.pop(ctx);
                _executeCheckOut(notes: fullReason);
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('تأكيد الانصراف بالمبرر', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.WarningColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeCheckOut({String? notes}) async {
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

    final user = context.read<AuthService>().currentUser;
    final int empId = user?.employeeId ?? user?.id ?? 1;
    final isAtHQ = AppConstants.isWithinHQ(pos.latitude, pos.longitude);

    final payload = {
      'employeeId': empId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'location': isAtHQ ? 'HQ' : 'Field',
      'notes': notes,
    };

    bool isOfflineMode = false;

    try {
      final api = context.read<AuthService>().api;
      await api.checkOut(
        empId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        notes: notes,
      );
    } catch (e) {
      isOfflineMode = true;
      await OfflineSyncService.queueCheckOut(payload);
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pending = await OfflineSyncService.getPendingCount();

    if (mounted) {
      setState(() {
        _isCheckedIn = false;
        _checkInTime = null;
        _checkInPhoto = null;
        _isLoading = false;
        _pendingSyncCount = pending;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOfflineMode
                ? '📡 تم حفظ الانصراف محلياً — ستتم المزامنة تلقائياً'
                : '✅ تم تسجيل الانصراف بنجاح وإغلاق بطاقة الدوام لليوم',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: isOfflineMode ? const Color(0xFFD97706) : AppTheme.SuccessColor,
          duration: const Duration(seconds: 4),
        ),
      );

      _showCheckOutProof(
        employeeName: user?.fullName ?? '',
        latitude: pos.latitude,
        longitude: pos.longitude,
        notes: notes,
        isOffline: isOfflineMode,
      );
    }
  }

  void _showAttendanceProof({bool isOffline = false}) {
    final user = context.read<AuthService>().currentUser;
    QRCodeScreen.show(
      context,
      record: {
        'type': 'checkin',
        'employeeName': user?.fullName ?? '',
        'date': DateTime.now().toString().split(' ')[0],
        'time': _checkInTime ?? DateTime.now().toString().substring(11, 19),
        'latitude': _checkInLat ?? AppConstants.hqLatitude,
        'longitude': _checkInLng ?? AppConstants.hqLongitude,
        'photo': _checkInPhoto,
        'id': DateTime.now().millisecondsSinceEpoch,
        'status': isOffline ? 'OFFLINE_PENDING_SYNC' : 'VERIFIED_ACTIVE',
      },
      title: isOffline ? 'إثبات الحضور (محلي)' : 'بطاقة الإثبات الرقمي (حضور معتمد)',
    );
  }

  void _showCheckOutProof({
    required String employeeName,
    required double latitude,
    required double longitude,
    String? notes,
    bool isOffline = false,
  }) {
    QRCodeScreen.show(
      context,
      record: {
        'type': 'checkout',
        'employeeName': employeeName,
        'date': DateTime.now().toString().split(' ')[0],
        'time': DateTime.now().toString().substring(11, 19),
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes ?? 'انصراف نظامي',
        'id': DateTime.now().millisecondsSinceEpoch,
        'status': isOffline ? 'OFFLINE_PENDING_SYNC' : 'SYNCED',
      },
      title: isOffline ? 'إثبات الانصراف (وضع عدم الاتصال)' : 'إثبات الانصراف الرسمي',
    );
  }

  void _showVisitProofModal(Map<String, dynamic> visit) {
    final user = context.read<AuthService>().currentUser;
    final bool isOffline = visit['IsOffline'] == true;
    final String shop = (visit['TraderName'] ?? visit['ShopName'] ?? 'معاينة تجارية').toString();
    final String time = _formatTime(visit['CreatedAt'] ?? visit['VisitTime'] ?? visit['CheckInTime']);
    final dynamic lat = visit['Latitude'];
    final dynamic lng = visit['Longitude'];
    final String? photoBase64 = visit['Photo']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.AccentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, color: AppTheme.AccentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'توقيت المعاينة: $time • ${isOffline ? "قيد المزامنة" : "مثبتة سحابياً"}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOffline ? const Color(0xFFD97706) : AppTheme.SuccessColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOffline ? 'معلق' : 'معتمد',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photoBase64 != null && photoBase64.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(photoBase64),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (lat != null && lng != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: AppTheme.AccentColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'الإحداثيات: ${lat.toString().substring(0, lat.toString().length > 7 ? 7 : lat.toString().length)}, ${lng.toString().substring(0, lng.toString().length > 7 ? 7 : lng.toString().length)}',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  QRCodeScreen.show(
                    context,
                    record: {
                      'type': 'visit',
                      'employeeName': user?.fullName ?? '',
                      'shopName': shop,
                      'time': time,
                      'latitude': lat,
                      'longitude': lng,
                      'id': visit['Id'] ?? DateTime.now().millisecondsSinceEpoch,
                      'status': isOffline ? 'OFFLINE_PENDING_SYNC' : 'VERIFIED_VISIT',
                    },
                    title: 'رمز الإثبات الرقمي للزيارة (QR Pass)',
                  );
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('عرض رمز الاستجابة السريعة (QR Pass)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.AccentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordVisit() {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String shopType = 'محل تجزئة / سوبرماركت';
    String? capturedPhoto;
    Position? currentPos;
    bool isLocating = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Fetch GPS in the background once when dialog opens
          if (isLocating && currentPos == null) {
            _getPosition().then((pos) {
              if (ctx.mounted) {
                setDialogState(() {
                  currentPos = pos ?? Position(
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
                  isLocating = false;
                });
              }
            });
          }

          final double displayLat = currentPos?.latitude ?? AppConstants.hqLatitude;
          final double displayLng = currentPos?.longitude ?? AppConstants.hqLongitude;

          return AlertDialog(
            backgroundColor: AppTheme.CardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              loc.recordVisit,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.SuccessColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.SuccessColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLocating
                                ? 'جاري تحديد إحداثيات الموقع (GPS)...'
                                : '${displayLat.toStringAsFixed(4)}, ${displayLng.toStringAsFixed(4)} (دقيق)',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.SuccessColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'اسم المحل / التاجر المعاين *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: shopType,
                    dropdownColor: AppTheme.CardColor,
                    decoration: InputDecoration(
                      labelText: 'طبيعة النشاط التجاري',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'محل تجزئة / سوبرماركت', child: Text('محل تجزئة / مواد غذائية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'مخبزة / صناعة حلويات', child: Text('مخبزة / صناعة حلويات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'قصابة / لحوم ودواجن', child: Text('قصابة / لحوم ودواجن', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'سوق الجملة للخضر والفواكه', child: Text('سوق الجملة للخضر والفواكه', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'وحدة إنتاج / مصنع', child: Text('وحدة إنتاج / تحويل صناعي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'أخرى', child: Text('أخرى', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => shopType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات المعاينة (الأسعار، النظافة، الفوترة...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Photo capture row
                  if (capturedPhoto != null && capturedPhoto!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(capturedPhoto!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final photo = await _pickPhoto(fromGallery: false);
                            if (photo != null && ctx.mounted) {
                              setDialogState(() => capturedPhoto = photo);
                            }
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: Text(
                            capturedPhoto != null ? 'تغيير الصورة' : 'التقاط بالكاميرا',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final photo = await _pickPhoto(fromGallery: true);
                            if (photo != null && ctx.mounted) {
                              setDialogState(() => capturedPhoto = photo);
                            }
                          },
                          icon: const Icon(Icons.photo_library, size: 16),
                          label: const Text(
                            'من المعرض',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: Text(loc.cancel, style: const TextStyle(fontFamily: 'Tajawal')),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  final auth = context.read<AuthService>();
                  final user = auth.currentUser;
                  final messenger = ScaffoldMessenger.of(context);
                  final int empId = user?.employeeId ?? user?.id ?? 1;
                  final shopNameVal = nameCtrl.text.trim().isEmpty ? 'محل تجاري - معاينة ميدانية' : nameCtrl.text.trim();

                  final double posLat = currentPos?.latitude ?? AppConstants.hqLatitude;
                  final double posLng = currentPos?.longitude ?? AppConstants.hqLongitude;

                  final payload = {
                    'employeeId': empId,
                    'latitude': posLat,
                    'longitude': posLng,
                    'photo': capturedPhoto,
                    'shopName': shopNameVal,
                    'shopType': shopType,
                    'notes': notesCtrl.text.trim(),
                  };

                  bool isOfflineMode = false;
                  try {
                    final api = auth.api;
                    await api.recordVisit(
                      employeeId: empId,
                      latitude: posLat,
                      longitude: posLng,
                      photo: capturedPhoto,
                      shopName: shopNameVal,
                      shopType: shopType,
                      notes: payload['notes'] as String,
                    );
                  } catch (e) {
                    isOfflineMode = true;
                    await OfflineSyncService.queueVisit(payload);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;

                  _loadStatus();

                  final Map<String, dynamic> visitRecord = {
                    'TraderName': shopNameVal,
                    'ShopName': shopNameVal,
                    'ActivityType': shopType,
                    'CreatedAt': DateTime.now().toIso8601String(),
                    'Latitude': posLat,
                    'Longitude': posLng,
                    'Photo': capturedPhoto,
                    'Notes': payload['notes'],
                    'IsOffline': isOfflineMode,
                  };

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isOfflineMode ? '📡 تم حفظ المعاينة محلياً بنجاح' : '✅ تم توثيق المعاينة الميدانية بنجاح',
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      backgroundColor: isOfflineMode ? const Color(0xFFD97706) : AppTheme.SuccessColor,
                      action: SnackBarAction(
                        label: 'عرض الـ QR',
                        textColor: Colors.white,
                        onPressed: () => _showVisitProofModal(visitRecord),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.SuccessColor),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(loc.save, style: const TextStyle(fontFamily: 'Tajawal')),
              ),
            ],
          );
        },
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
                loc.isArabic ? 'المفتشية الميدانية' : 'Contrôle Terrain',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            if (_pendingSyncCount > 0)
              InkWell(
                onTap: _isSyncing ? null : () => _syncPendingItems(silent: false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isSyncing
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.sync, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$_pendingSyncCount معلق',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.cloud_done, color: Color(0xFF10B981), size: 20),
                tooltip: 'جميع البيانات متزامنة',
                onPressed: () => _syncPendingItems(silent: false),
              ),
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
              // Offline banner
              if (_pendingSyncCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'يوجد $_pendingSyncCount عمليات مسجلة محلياً في انتظار المزامنة مع السيرفر.',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Color(0xFFFCD34D),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isSyncing ? null : () => _syncPendingItems(silent: false),
                        child: Text(
                          _isSyncing ? 'جاري...' : 'مزامنة الآن',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                            user?.serviceName ?? loc.roleInspector,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isCheckedIn ? AppTheme.SuccessColor : AppTheme.WarningColor,
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
              const SizedBox(height: 16),

              // Active Assignment / Mission Order Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'أمر المهمة والقطاع التفتيشي لليوم',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ساري المفعول',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _activeProgram != null
                          ? (_activeProgram!['Title']?.toString() ?? 'برنامج مراقبة الأسعار وإشهارها')
                          : 'مراقبة الممارسات التجارية والمطابقة وقمع الغش',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeProgram != null
                          ? 'القطاع المستهدف: ${_activeProgram!['TargetArea'] ?? "بلدية سطيف والعلمة"} • ${_activeProgram!['FocusPoints'] ?? "تجار الجملة والتجزئة"}'
                          : 'القطاع: وسط مدينة سطيف والأسواق الجوارية • الهدف: التحقق من إشهار الأسعار والفوترة ومطابقة المواد الحساسة',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Digital Proofs & QR Passes Action Banner
              if (_isCheckedIn)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_2, color: Color(0xFFA5B4FC), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'محفظة الإثباتات الرقمية (QR Pass)',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'عرض بطاقة الحضور والزيارات المثبتة للمسؤولين',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showAttendanceProof(isOffline: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF818CF8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'عرض البطاقة',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleSmartCheckOut,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.exit_to_app, color: AppTheme.WarningColor),
                          label: const Text(
                            'تسجيل الانصراف الرسمي',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.WarningColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.WarningColor, width: 1.5),
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
                              color: AppTheme.TextSecondary.withValues(alpha: 0.5),
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
                            _isLoading ? loc.checkInProgress : loc.checkInWithCamera,
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

              // Visit Action
              if (_isCheckedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _recordVisit,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text(
                      'توثيق معاينة ميدانية جديدة بالصورة والـ GPS',
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
                    (v) {
                      final bool isItemOffline = v['IsOffline'] == true;
                      return InkWell(
                        onTap: () => _showVisitProofModal(v),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.CardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isItemOffline
                                  ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                  : AppTheme.BorderColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isItemOffline
                                          ? const Color(0xFFD97706)
                                          : AppTheme.SuccessColor)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: isItemOffline
                                      ? const Color(0xFFD97706)
                                      : AppTheme.SuccessColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${v['TraderName'] ?? v['ShopName'] ?? (loc.isArabic ? 'معاينة تجارية' : 'Visite')}',
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (isItemOffline) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD97706)
                                                  .withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'معلق للمزامنة',
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 9,
                                                color: Color(0xFFFCD34D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${v['LocationName'] ?? (v['ShopName'] ?? '')} • ${_formatTime(v['CreatedAt'] ?? v['VisitTime'] ?? v['CheckInTime'])}',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 11,
                                        color: AppTheme.TextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.qr_code, color: AppTheme.AccentColor, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
