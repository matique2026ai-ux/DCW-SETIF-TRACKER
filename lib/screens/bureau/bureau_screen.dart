import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';

class BureauScreen extends StatefulWidget {
  const BureauScreen({super.key});

  @override
  State<BureauScreen> createState() => _BureauScreenState();
}

class _BureauScreenState extends State<BureauScreen> {
  List<Map<String, dynamic>> _deductions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthService>().api;
      final data = await api.getDeductions();
      if (mounted)
        setState(() {
          _deductions = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pending = _deductions.where((d) => d['Status'] == 'pending').toList();

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
                  child: Icon(Icons.assignment, size: 18, color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text(
                loc.roleBureau,
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
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.AccentColor),
              )
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pending.isEmpty
                          ? AppTheme.SuccessColor.withValues(alpha: 0.1)
                          : AppTheme.WarningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (pending.isEmpty
                                    ? AppTheme.SuccessColor
                                    : AppTheme.WarningColor)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pending.isEmpty
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: pending.isEmpty
                              ? AppTheme.SuccessColor
                              : AppTheme.WarningColor,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          '${loc.pendingDeductions}: ${pending.length}',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: AppTheme.SuccessColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              loc.noPendingDeductions,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                color: AppTheme.TextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pending.length,
                        itemBuilder: (ctx, i) {
                          final d = pending[i];
                          final name = d['NomAr'] != null
                              ? '${d['NomAr']} ${d['PrenomAr']}'
                              : '${d['Nom']} ${d['Prenom']}';
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.CardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.BorderColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.WarningColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: AppTheme.WarningColor,
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '${d['Service'] ?? ''}',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 11,
                                              color: AppTheme.TextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (d['DaysCount'] != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.DangerColor.withValues(
                                                alpha: 0.15,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${d['DaysCount']} ${loc.days}',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.DangerColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.BackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${d['Reason']}',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${loc.from}: ${d['RequestedByName'] ?? '-'}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _approve(d['Id'] as int),
                                        icon: Icon(Icons.check, size: 18),
                                        label: Text(
                                          loc.approve,
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.SuccessColor,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _reject(d['Id'] as int),
                                        icon: Icon(Icons.close, size: 18),
                                        label: Text(
                                          loc.reject,
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppTheme.DangerColor,
                                          ),
                                          foregroundColor: AppTheme.DangerColor,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _approve(int id) async {
    final loc = AppLocalizations.of(context);
    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;
      await api.approveDeduction(id: id, approvedBy: user!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅'), backgroundColor: AppTheme.SuccessColor),
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppTheme.DangerColor),
      );
    }
  }

  Future<void> _reject(int id) async {
    try {
      final api = context.read<AuthService>().api;
      final user = context.read<AuthService>().currentUser;
      await api.rejectDeduction(id: id, approvedBy: user!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الرفض'),
          backgroundColor: AppTheme.WarningColor,
        ),
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppTheme.DangerColor),
      );
    }
  }
}
