import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final api = context.read<AuthService>().api;
      final programs = await api.getPrograms();
      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrograms = _selectedFilter == 'all'
        ? _programs
        : _programs.where((p) => p['Type'] == _selectedFilter).toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: AppTheme.BackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _filterChip('الكل', 'all'),
              _filterChip('أسبوعي', 'weekly'),
              _filterChip('شهري', 'monthly'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredPrograms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: AppTheme.BorderColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد برامج',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPrograms,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredPrograms.length,
                    itemBuilder: (context, index) {
                      final program = filteredPrograms[index];
                      final doneCount = (program['DoneCount'] ?? 0) as int;
                      final totalCount = (program['TotalCount'] ?? 0) as int;
                      final isWeekly = program['Type'] == 'weekly';
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (program['Title'] ?? '') as String,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.TextPrimary,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWeekly
                                          ? AppTheme.AccentColor.withValues(
                                              alpha: 0.1,
                                            )
                                          : AppTheme.PrimaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isWeekly ? 'أسبوعي' : 'شهري',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 11,
                                        color: isWeekly
                                            ? AppTheme.AccentColor
                                            : AppTheme.PrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                (program['WeekDate'] ?? '') as String,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: AppTheme.TextSecondary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: totalCount > 0
                                    ? doneCount / totalCount
                                    : 0,
                                backgroundColor: AppTheme.BorderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  doneCount / totalCount > 0.7
                                      ? AppTheme.SuccessColor
                                      : AppTheme.AccentColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$doneCount / $totalCount منجز',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: AppTheme.TextSecondary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.PrimaryColor : AppTheme.CardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.PrimaryColor : AppTheme.BorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: isSelected ? Colors.white : AppTheme.TextSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
