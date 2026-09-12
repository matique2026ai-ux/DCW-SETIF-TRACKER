const String appName = 'DCW-SETIF-TRACKER';
const String appVersion = '1.0.0';
const String appOrganization = 'com.dcwsetif';

const String primaryColorHex = '#881337';
const String accentColorHex = '#D4AF37';
const String sidebarColorHex = '#4C0519';
const String backgroundColorHex = '#FAF5F5';

const String dbName = 'drh_tracker.db';
const int dbVersion = 1;

const String tableNameEmployees = 'employees';
const String tableNamePrograms = 'programs';
const String tableNameAssignments = 'assignments';
const String tableNameAttendance = 'attendance';
const String tableNameAbsences = 'absences';
const String tableNameDeductions = 'deductions';
const String tableNameUsers = 'users';

enum UserRole { director, headOfDept, bureau, inspector }

const Map<UserRole, String> roleNames = {
  UserRole.director: 'المدير الولائي',
  UserRole.headOfDept: 'رئيس المصلحة',
  UserRole.bureau: 'مكتب المستخدمين',
  UserRole.inspector: 'المفتش',
};

const List<String> departments = [
  'حماية المستهلك وقمع الغش',
  'مراقبة الممارسات التجارية والمضادة للمنافسة',
];

class Constants {
  static const String appName = 'DCW-SETIF-TRACKER';
  static const String appVersion = '1.0.0';
  static const String appOrganization = 'com.dcwsetif';
  static const String dbName = 'drh_tracker.db';
  static const int dbVersion = 1;
}
