import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';

class DirectorDeductionsTab extends StatefulWidget {
  const DirectorDeductionsTab({super.key});

  @override
  State<DirectorDeductionsTab> createState() => _DirectorDeductionsTabState();
}

class _DirectorDeductionsTabState extends State<DirectorDeductionsTab> {
  List<Map<String, dynamic>> _employees = [];
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
      final emp = await api.getEmployees();
      final ded = await api.getDeductions();
      if (mounted)
        setState(() {
          _employees = emp;
          _deductions = ded;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _requestDeduction(Map<String, dynamic> employee) {
    final loc = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.requestDeduction,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Tajawalal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.AccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.AccentColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${employee['NomAr'] ?? employee['Nom']} ${employee['PrenomAr'] ?? employee['Prenom']}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: loc.deductionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: loc.deductionDays,
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
              if (reasonCtrl.text.isEmpty) return;
              try {
                final api = context.read<AuthService>().api;
                final user = context.read<AuthService>().currentUser;
                await api.requestDeduction(
                  employeeId: employee['Id'] as int,
                  requestedBy: user!.id!,
                  reason: reasonCtrl.text,
                  daysCount: int.tryParse(daysCtrl.text),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅'),
                    backgroundColor: AppTheme.SuccessColor,
                  ),
                );
                _load();
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
              backgroundColor: AppTheme.DangerColor,
            ),
            child: Text(loc.submit, style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading)
      return Center(
        child: CircularProgressIndicator(color: AppTheme.AccentColor),
      );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEmployeePicker(),
              icon: Icon(Icons.person_remove),
              label: Text(
                loc.requestDeduction,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.DangerColor,
                padding: EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              loc.pendingDeductions,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: _deductions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppTheme.SuccessColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        loc.noDeductions,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _deductions.length,
                  itemBuilder: (context, index) {
                    final d = _deductions[index];
                    final name = d['NomAr'] != null
                        ? '${d['NomAr']} ${d['PrenomAr']}'
                        : '${d['Nom']} ${d['Prenom']}';
                    final status = d['Status'] ?? 'pending';
                    final statusColor = status == 'approved'
                        ? AppTheme.SuccessColor
                        : status == 'rejected'
                        ? AppTheme.DangerColor
                        : AppTheme.WarningColor;
                    final statusText = status == 'approved'
                        ? loc.approved
                        : status == 'rejected'
                        ? loc.rejected
                        : loc.pending;
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.CardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.BorderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.money_off,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${d['Reason']}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (d['DaysCount'] != null)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.DangerColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEmployeePicker() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.BorderColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    loc.selectEmployee,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final e = _employees[index];
                  final name = e['NomAr'] != null
                      ? '${e['NomAr']} ${e['PrenomAr']}'
                      : '${e['Nom']} ${e['Prenom']}';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.PrimaryColor.withValues(
                        alpha: 0.2,
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.PrimaryColor,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${e['Service'] ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppTheme.TextSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _requestDeduction(e);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
