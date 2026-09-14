import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/utils/constants.dart';
import 'package:drh_setif_tracker/screens/common/qr_code_screen.dart';

class DirectorMapTab extends StatefulWidget {
  const DirectorMapTab({super.key});

  @override
  State<DirectorMapTab> createState() => _DirectorMapTabState();
}

class _DirectorMapTabState extends State<DirectorMapTab> {
  List<Map<String, dynamic>> _mapData = [];
  bool _isLoading = true;
  bool _isLocating = false;
  LatLng? _directorLiveLocation;
  Timer? _liveRefreshTimer;
  final MapController _mapController = MapController();
  String _selectedMapStyle = 'satellite'; // 'satellite', 'osm'

  static const LatLng _setifCenter = LatLng(AppConstants.hqLatitude, AppConstants.hqLongitude);

  @override
  void initState() {
    super.initState();
    _loadData();
    // Live Auto-Refresh every 12 seconds
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      final api = context.read<AuthService>().api;
      final data = await api.getMapData();
      if (mounted) {
        setState(() {
          _mapData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final target = (currentZoom + 1.2).clamp(3.0, 19.0);
      _mapController.move(_mapController.camera.center, target);
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final target = (currentZoom - 1.2).clamp(3.0, 19.0);
      _mapController.move(_mapController.camera.center, target);
    } catch (_) {}
  }

  Future<void> _locateDirectorLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _mapController.move(_setifCenter, 13.5);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 تم التوجيه إلى مركز ولاية سطيف (صلاحية GPS غير مفعلة في المتصفح)', style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: AppTheme.WarningColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final livePoint = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _directorLiveLocation = livePoint);
        _mapController.move(livePoint, 16.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 تم تحديد موقعك المباشر بنجاح (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.SuccessColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _mapController.move(_setifCenter, 13.5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 تم التوجيه إلى مركز ولاية سطيف والمقر الرئيسي', style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.AccentColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final present = _mapData
        .where((e) => e['hasCheckedIn'] == true && e['isCheckedOut'] != true)
        .toList();
    final absent = _mapData.where((e) => e['hasCheckedIn'] != true).toList();

    // Collect all visits markers
    final List<Marker> visitMarkers = [];
    for (final emp in _mapData) {
      final visits = (emp['visits'] as List?) ?? [];
      for (final v in visits) {
        if (v['latitude'] != null && v['longitude'] != null) {
          final double vLat = (v['latitude'] as num).toDouble();
          final double vLng = (v['longitude'] as num).toDouble();
          final visitMap = Map<String, dynamic>.from(v as Map);
          final String empName = emp['name']?.toString() ?? 'مفتش ميداني';
          visitMarkers.add(
            Marker(
              point: LatLng(vLat, vLng),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => _showVisitDetailsModal(visitMap, empName),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                ),
              ),
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: _setifCenter, initialZoom: 13),
          children: [
            if (_selectedMapStyle == 'satellite') ...[
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'DCW-SETIF-TRACKER',
                maxZoom: 19,
              ),
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'DCW-SETIF-TRACKER',
                maxZoom: 19,
              ),
            ] else ...[
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'DCW-SETIF-TRACKER',
                maxZoom: 19,
              ),
            ],

            // Geofence Circles for All Regional Inspectorates & Annexes in Setif Province
            CircleLayer(
              circles: AppConstants.allInspectorates.map((insp) {
                return CircleMarker(
                  point: LatLng(insp.latitude, insp.longitude),
                  radius: insp.radiusMeters,
                  useRadiusInMeter: true,
                  color: (insp.isMainDirectorate ? AppTheme.AccentColor : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                  borderColor: insp.isMainDirectorate ? AppTheme.AccentColor : const Color(0xFF0284C7),
                  borderStrokeWidth: 1.5,
                );
              }).toList(),
            ),

            MarkerLayer(
              markers: [
                // Regional Inspectorates & Main HQ Markers
                ...AppConstants.allInspectorates.map((insp) {
                  return Marker(
                    point: LatLng(insp.latitude, insp.longitude),
                    width: insp.isMainDirectorate ? 44 : 38,
                    height: insp.isMainDirectorate ? 44 : 38,
                    child: Tooltip(
                      message: insp.nameAr,
                      child: GestureDetector(
                        onTap: () {
                          _showInspectorateHQModal(insp);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: insp.isMainDirectorate ? AppTheme.AccentColor : const Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            insp.isMainDirectorate ? Icons.account_balance : Icons.apartment,
                            color: Colors.white,
                            size: insp.isMainDirectorate ? 22 : 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Field Visit Markers (Stores inspected today)
                ...visitMarkers,

                // Live Director / User Current Location Marker
                if (_directorLiveLocation != null)
                  Marker(
                    point: _directorLiveLocation!,
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                // Active In-Field Inspectors Markers (Excludes checked out agents to respect privacy)
                ..._mapData
                    .where(
                      (e) =>
                          e['latitude'] != null &&
                          e['hasCheckedIn'] == true &&
                          e['isCheckedOut'] != true,
                    )
                    .map((emp) {
                      final lat = (emp['latitude'] as num).toDouble();
                      final lng = (emp['longitude'] as num).toDouble();
                      final isOut = emp['isCheckedOut'] == true;
                      final int vCount = (emp['visitsCount'] as num?)?.toInt() ?? 0;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _showInspectorModal(emp),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? const Color(0xFF64748B)
                                      : AppTheme.SuccessColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isOut
                                              ? const Color(0xFF64748B)
                                              : AppTheme.SuccessColor)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              if (vCount > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.AccentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$vCount',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
              ],
            ),
          ],
        ),

        // Stats card on top
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.CardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.BorderColor.withValues(alpha: 0.3),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 12),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.AccentColor,
                    ),
                  )
                : Row(
                    children: [
                      _legend(
                        loc.inField,
                        present.length,
                        AppTheme.SuccessColor,
                      ),
                      const SizedBox(width: 14),
                      _legend('معاينات ميدانية', visitMarkers.length, const Color(0xFF38BDF8)),
                      const SizedBox(width: 14),
                      _legend(loc.absent, absent.length, AppTheme.DangerColor),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadData,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.AccentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: AppTheme.AccentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Top Controls: Map Style Switcher + Search Agent Button
        Positioned(
          top: 72,
          right: 12,
          left: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search Agent Button
              GestureDetector(
                onTap: _showSearchInspectorSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.CardColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 16, color: Color(0xFFD4AF37)),
                      SizedBox(width: 6),
                      Text(
                        'بحث عن عون...',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map Layer Switcher (100% Free - Satellite vs Streets)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.CardColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.BorderColor.withValues(alpha: 0.4),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _styleChip('satellite', 'أقمار صناعية'),
                    _styleChip('osm', 'خريطة الشوارع'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Regional Inspectorates Quick Jump Filter Chips
        Positioned(
          top: 118,
          right: 12,
          left: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _inspectorateFilterChip('الكل', '📌 كل الولاية', _setifCenter, 11),
                ...AppConstants.allInspectorates.map((insp) {
                  return _inspectorateFilterChip(
                    insp.id,
                    insp.isMainDirectorate ? '🏢 المقر الرئيسي' : '🏛️ ${insp.nameAr.replaceAll('المفتشية الإقليمية للتجارة — ', '').replaceAll('الملحقة التجارية — ', 'ملحقة ')}',
                    LatLng(insp.latitude, insp.longitude),
                    15.5,
                    inspectorate: insp,
                  );
                }),
              ],
            ),
          ),
        ),

        // Map Control Buttons
        Positioned(
          bottom: 24,
          left: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(
                Icons.add,
                _zoomIn,
                tooltip: 'تكبير الخريطة (+)',
              ),
              const SizedBox(height: 10),
              _actionButton(
                Icons.remove,
                _zoomOut,
                tooltip: 'تصغير الخريطة (-)',
              ),
              const SizedBox(height: 10),
              _actionButton(
                Icons.my_location,
                _locateDirectorLocation,
                tooltip: 'تحديد موقعي المباشر (GPS)',
                isLoading: _isLocating,
                highlightColor: AppTheme.AccentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _styleChip(String styleKey, String label) {
    final isSelected = _selectedMapStyle == styleKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedMapStyle = styleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.AccentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.TextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    VoidCallback onPressed, {
    String? tooltip,
    bool isLoading = false,
    Color? highlightColor,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          customBorder: const CircleBorder(),
          splashColor: AppTheme.AccentColor.withValues(alpha: 0.4),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1638),
              shape: BoxShape.circle,
              border: Border.all(
                color: highlightColor ?? const Color(0xFFD4AF37).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFFD4AF37),
                      ),
                    )
                  : Icon(
                      icon,
                      color: highlightColor ?? const Color(0xFFFFF6D6),
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: AppTheme.TextSecondary,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatAttendanceTime(dynamic rawTime) {
    if (rawTime == null || rawTime.toString().isEmpty) return '---';
    try {
      final dt = DateTime.parse(rawTime.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '$hh:$mm ($yyyy-$month-$day)';
    } catch (_) {
      return rawTime.toString().replaceAll('T', ' ').substring(0, 16);
    }
  }

  void _showInspectorModal(Map<String, dynamic> emp) {
    final String name = (emp['name'] ?? 'مفتش').toString();
    final String service = (emp['service'] ?? 'مديرية التجارة').toString();
    final String checkInStr = _formatAttendanceTime(emp['checkInTime']);
    final bool isPresent = emp['hasCheckedIn'] == true;
    final bool isOut = emp['isCheckedOut'] == true;
    final List<dynamic> visits = (emp['visits'] as List<dynamic>?) ?? [];
    final String? checkInPhoto = emp['checkInPhoto']?.toString();

    // Precise administrative status:
    String statusText = 'غائب (لم يسجل)';
    Color statusColor = AppTheme.DangerColor;
    if (isOut) {
      statusText = 'انصرف';
      statusColor = const Color(0xFF64748B);
    } else if (isPresent) {
      if (visits.isNotEmpty) {
        statusText = 'نشط في الميدان (${visits.length} معاينات)';
        statusColor = const Color(0xFF38BDF8);
      } else {
        statusText = 'حاضر بالمقر (مسجل حضور)';
        statusColor = AppTheme.SuccessColor;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: statusColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(service, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.TextSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.BorderColor),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, 'توقيت الحضور', checkInStr),
            if (emp['notes'] != null && emp['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.notes, 'ملاحظة الانصراف/المبرر', emp['notes'].toString()),
            ],
            const SizedBox(height: 8),
            _infoRow(Icons.store, 'المعاينات المنجزة اليوم', '${visits.length} معاينات'),
            if (checkInPhoto != null && checkInPhoto.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('صورة إثبات الحضور الميداني:', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(checkInPhoto),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (visits.isNotEmpty) ...[
              const Text('سجل المحلات المعاينة اليوم:', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...visits.map((v) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, color: Color(0xFF38BDF8), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${v['shopName']} • ${v['time'] != null ? v['time'].toString().substring(11, 16) : ""}',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: AppTheme.AccentColor, size: 18),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showVisitDetailsModal(Map<String, dynamic>.from(v as Map), name);
                          },
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  QRCodeScreen.show(
                    context,
                    record: {
                      'type': 'inspector_badge',
                      'employeeName': name,
                      'service': service,
                      'date': DateTime.now().toString().split(' ')[0],
                      'checkInTime': checkInStr,
                      'visitsCount': visits.length,
                      'status': 'VERIFIED_OFFICIAL_INSPECTOR',
                    },
                    title: 'البطاقة الرقمية الرسمية للمفتش',
                  );
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('فحص الإثبات الرقمي والـ QR للعون', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitDetailsModal(Map<String, dynamic> v, String inspectorName) {
    final String shop = (v['shopName'] ?? 'محل تجاري').toString();
    final String? photo = v['photo']?.toString();
    final dynamic lat = v['latitude'];
    final dynamic lng = v['longitude'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.SuccessColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('المفتش: $inspectorName', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.TextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (photo != null && photo.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(photo),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (lat != null && lng != null)
              Text('الإحداثيات الجغرافية: $lat, $lng', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  QRCodeScreen.show(
                    context,
                    record: {
                      'type': 'visit_evidence',
                      'shop': shop,
                      'inspector': inspectorName,
                      'latitude': lat,
                      'longitude': lng,
                      'id': v['id'] ?? DateTime.now().millisecondsSinceEpoch,
                    },
                    title: 'إثبات المعاينة الميدانية (QR)',
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('عرض رمز الاستجابة السريعة للزيارة', style: TextStyle(fontFamily: 'Tajawal')),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.AccentColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: AppTheme.TextSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchInspectorSheet() {
    String query = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final q = query.trim().toLowerCase();
          final filtered = _mapData.where((emp) {
            if (q.isEmpty) return true;
            final name = (emp['name'] ?? '').toString().toLowerCase();
            final service = (emp['service'] ?? '').toString().toLowerCase();
            return name.contains(q) || service.contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppTheme.CardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_search, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'البحث عن عون ومتابعة حالته الميدانية',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: (val) => setSheetState(() => query = val),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، اللقب أو المصلحة...',
                      hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'لم يتم العثور على أي عون يطابق البحث',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: AppTheme.TextSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final emp = filtered[index];
                            final name = emp['name']?.toString() ?? 'عون رقابة';
                            final service = emp['service']?.toString() ?? 'مديرية التجارة';
                            final bool hasCheckedIn = emp['hasCheckedIn'] == true;
                            final bool isCheckedOut = emp['isCheckedOut'] == true;
                            final visits = (emp['visits'] as List?) ?? [];
                            final double? lat = (emp['latitude'] as num?)?.toDouble();
                            final double? lng = (emp['longitude'] as num?)?.toDouble();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasCheckedIn
                                      ? AppTheme.SuccessColor.withValues(alpha: 0.4)
                                      : Colors.white10,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasCheckedIn
                                      ? (isCheckedOut
                                          ? Colors.grey.withValues(alpha: 0.3)
                                          : AppTheme.SuccessColor.withValues(alpha: 0.2))
                                      : AppTheme.DangerColor.withValues(alpha: 0.2),
                                  child: Icon(
                                    hasCheckedIn ? Icons.location_on : Icons.person_off,
                                    color: hasCheckedIn
                                        ? (isCheckedOut ? Colors.grey : AppTheme.SuccessColor)
                                        : AppTheme.DangerColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '$service • ${hasCheckedIn ? (isCheckedOut ? 'انصرف' : 'في الميدان (${visits.length} زيارات)') : 'لم يسجل الحضور اليوم'}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: hasCheckedIn ? AppTheme.SuccessColor : AppTheme.TextSecondary,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFFD4AF37),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  if (lat != null && lng != null && (lat != 0 || lng != 0)) {
                                    _mapController.move(LatLng(lat, lng), 16);
                                    _showInspectorModal(emp);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '⚠️ العون ($name) لم يسجل حضوره اليوم بعد لتحديد موقعه المباشر',
                                          style: const TextStyle(fontFamily: 'Tajawal'),
                                        ),
                                        backgroundColor: AppTheme.CardColor,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _inspectorateFilterChip(String id, String label, LatLng center, double zoom, {InspectorateHQ? inspectorate}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () {
          _mapController.move(center, zoom);
          if (inspectorate != null) {
            _showInspectorateHQModal(inspectorate);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.CardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inspectorate != null && inspectorate.isMainDirectorate
                  ? const Color(0xFFD4AF37)
                  : AppTheme.BorderColor.withValues(alpha: 0.4),
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showInspectorateHQModal(InspectorateHQ insp) {
    final nearbyEmps = _mapData.where((e) {
      if (e['latitude'] == null || e['longitude'] == null) return false;
      final lat = (e['latitude'] as num).toDouble();
      final lng = (e['longitude'] as num).toDouble();
      final d = AppConstants.distanceBetween(lat, lng, insp.latitude, insp.longitude);
      return d <= insp.radiusMeters;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.CardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (insp.isMainDirectorate ? AppTheme.AccentColor : const Color(0xFF0284C7)).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      insp.isMainDirectorate ? Icons.account_balance : Icons.apartment,
                      color: insp.isMainDirectorate ? AppTheme.AccentColor : const Color(0xFF38BDF8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insp.nameAr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          insp.nameFr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: AppTheme.TextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _hqStatItem('الأعوان الحاضرون بالمقر', '${nearbyEmps.length}', AppTheme.SuccessColor),
                    _hqStatItem('نطاق الحضور الجغرافي', '${insp.radiusMeters.round()}م', const Color(0xFF38BDF8)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _mapController.move(LatLng(insp.latitude, insp.longitude), 16.0);
                        },
                        icon: const Icon(Icons.center_focus_strong, color: Colors.black, size: 18),
                        label: const Text(
                          'تركيز الخريطة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          QRCodeScreen.show(
                            context,
                            record: {
                              'type': 'OFFICIAL_INSPECTORATE_BADGE',
                              'inspectorateId': insp.id,
                              'name': insp.nameAr,
                              'latitude': insp.latitude,
                              'longitude': insp.longitude,
                              'date': DateTime.now().toIso8601String().split('T')[0],
                            },
                            title: 'الشارة الرقمية للمقر — ${insp.nameAr}',
                          );
                        },
                        icon: const Icon(Icons.qr_code_2, color: Color(0xFFD4AF37), size: 18),
                        label: const Text(
                          'الشارة الرقمية (QR)',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hqStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: AppTheme.TextSecondary,
          ),
        ),
      ],
    );
  }
}
