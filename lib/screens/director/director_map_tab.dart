import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';

class DirectorMapTab extends StatefulWidget {
  const DirectorMapTab({super.key});

  @override
  State<DirectorMapTab> createState() => _DirectorMapTabState();
}

class _DirectorMapTabState extends State<DirectorMapTab> {
  List<Map<String, dynamic>> _mapData = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  String _selectedMapStyle = 'satellite'; // 'satellite', 'voyager', 'dark'

  static const LatLng _setifCenter = LatLng(36.1898, 5.4108);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final present = _mapData
        .where((e) => e['hasCheckedIn'] == true && e['isCheckedOut'] != true)
        .toList();
    final absent = _mapData.where((e) => e['hasCheckedIn'] != true).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: _setifCenter, initialZoom: 13),
          children: [
            // Dynamic TileLayer based on selected style
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
            ] else if (_selectedMapStyle == 'dark') ...[
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'DCW-SETIF-TRACKER',
                maxZoom: 19,
              ),
            ] else ...[
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'DCW-SETIF-TRACKER',
                maxZoom: 19,
              ),
            ],

            // 500m Directorate HQ Geofence Circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _setifCenter,
                  radius: 500,
                  useRadiusInMeter: true,
                  color: AppTheme.AccentColor.withValues(alpha: 0.18),
                  borderColor: AppTheme.AccentColor,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            MarkerLayer(
              markers: [
                // HQ Badge Marker
                Marker(
                  point: _setifCenter,
                  width: 44,
                  height: 44,
                  child: Tooltip(
                    message: 'مقر مديرية التجارة لولاية سطيف',
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🏢 مقر مديرية التجارة وترقية الصادرات — سطيف (نطاق الحضور: 500 متر)',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                            backgroundColor: AppTheme.CardColor,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.AccentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // Active Inspectors Markers
                ..._mapData
                    .where(
                      (e) => e['latitude'] != null && e['hasCheckedIn'] == true,
                    )
                    .map((emp) {
                      final lat = (emp['latitude'] as num).toDouble();
                      final lng = (emp['longitude'] as num).toDouble();
                      final isOut = emp['isCheckedOut'] == true;
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showInfo(emp),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isOut
                                  ? AppTheme.WarningColor
                                  : AppTheme.SuccessColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOut
                                          ? AppTheme.WarningColor
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
                              size: 22,
                            ),
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
                      const SizedBox(width: 16),
                      _legend(loc.absent, absent.length, AppTheme.DangerColor),
                      const Spacer(),
                      _legend(loc.total, _mapData.length, AppTheme.AccentColor),
                      const SizedBox(width: 8),
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

        // Map Style Switcher (Floating below Stats Card)
        Positioned(
          top: 74,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                _styleChip('satellite', '🛰️ أقمار صناعية'),
                const SizedBox(width: 2),
                _styleChip('voyager', '🗺️ عصرية'),
                const SizedBox(width: 2),
                _styleChip('dark', '🌙 تكتيكية'),
              ],
            ),
          ),
        ),

        // Zoom & Recenter Controls
        Positioned(
          bottom: 24,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(Icons.add, () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom + 1,
                );
              }),
              const SizedBox(height: 8),
              _actionButton(Icons.remove, () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom - 1,
                );
              }),
              const SizedBox(height: 8),
              _actionButton(Icons.my_location, () {
                _mapController.move(_setifCenter, 13);
              }),
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

  Widget _actionButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.CardColor.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.BorderColor.withValues(alpha: 0.4),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: Icon(icon, color: AppTheme.TextPrimary, size: 20),
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
          '$label ',
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showInfo(Map<String, dynamic> emp) {
    final loc = AppLocalizations.of(context);
    final checkInStr = emp['checkInTime'] != null
        ? emp['checkInTime'].toString().replaceAll('T', ' ').substring(0, 16)
        : '---';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.BorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.SuccessColor,
                        AppTheme.SuccessColor.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${emp['name']}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${emp['service'] ?? ''}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.BorderColor),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, loc.checkIn, checkInStr),
            const SizedBox(height: 8),
            _infoRow(
              Icons.location_on,
              loc.inField,
              emp['hasCheckedIn'] == true ? '✅' : '❌',
            ),
            if (emp['latitude'] != null) ...[
              const SizedBox(height: 8),
              _infoRow(
                Icons.map,
                'GPS',
                '${(emp['latitude'] as num).toStringAsFixed(4)}, ${(emp['longitude'] as num).toStringAsFixed(4)}',
              ),
            ],
            const SizedBox(height: 16),
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
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
