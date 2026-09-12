import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';

class DirectorMapTab extends StatefulWidget {
  const DirectorMapTab({super.key});

  @override
  State<DirectorMapTab> createState() => _DirectorMapTabState();
}

class _DirectorMapTabState extends State<DirectorMapTab> {
  List<Map<String, dynamic>> _mapData = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();

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
      if (mounted)
        setState(() {
          _mapData = data;
          _isLoading = false;
        });
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
          options: MapOptions(initialCenter: _setifCenter, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'DCW-SETIF-TRACKER',
            ),
            MarkerLayer(
              markers: _mapData
                  .where(
                    (e) => e['latitude'] != null && e['hasCheckedIn'] == true,
                  )
                  .map((emp) {
                    final lat = (emp['latitude'] as num).toDouble();
                    final lng = (emp['longitude'] as num).toDouble();
                    final isOut = emp['isCheckedOut'] == true;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
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
                                color:
                                    (isOut
                                            ? AppTheme.WarningColor
                                            : AppTheme.SuccessColor)
                                        .withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),

        // Stats card
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.CardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.BorderColor.withValues(alpha: 0.3),
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            child: _isLoading
                ? Center(
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
                      SizedBox(width: 16),
                      _legend(loc.absent, absent.length, AppTheme.DangerColor),
                      Spacer(),
                      _legend(loc.total, _mapData.length, AppTheme.AccentColor),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loadData,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.AccentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
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
      ],
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
        SizedBox(width: 5),
        Text(
          '$label ',
          style: TextStyle(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
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
            SizedBox(height: 20),
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
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${emp['name']}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${emp['service'] ?? ''}',
                        style: TextStyle(
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
            SizedBox(height: 16),
            Divider(color: AppTheme.BorderColor),
            SizedBox(height: 8),
            _infoRow(
              Icons.access_time,
              loc.checkIn,
              emp['checkInTime'].toString().substring(11, 16),
            ),
            SizedBox(height: 8),
            _infoRow(
              Icons.location_on,
              loc.inField,
              emp['hasCheckedIn'] == true ? '✅' : '❌',
            ),
            if (emp['latitude'] != null) ...[
              SizedBox(height: 8),
              _infoRow(
                Icons.map,
                'GPS',
                '${(emp['latitude'] as num).toStringAsFixed(4)}, ${(emp['longitude'] as num).toStringAsFixed(4)}',
              ),
            ],
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.AccentColor),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: AppTheme.TextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
