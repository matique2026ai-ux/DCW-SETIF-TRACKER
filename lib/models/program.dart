class Program {
  final int? id;
  final String title;
  final String type;
  final String weekDate;
  final String monthYear;
  final int createdBy;
  final DateTime createdAt;

  Program({
    this.id,
    required this.title,
    required this.type,
    required this.weekDate,
    required this.monthYear,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'week_date': weekDate,
      'month_year': monthYear,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      weekDate: map['week_date'] as String,
      monthYear: map['month_year'] as String,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Assignment {
  final int? id;
  final int programId;
  final int employeeId;
  final String location;
  final String startDate;
  final String endDate;
  final String status;

  Assignment({
    this.id,
    required this.programId,
    required this.employeeId,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'program_id': programId,
      'employee_id': employeeId,
      'location': location,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as int?,
      programId: map['program_id'] as int,
      employeeId: map['employee_id'] as int,
      location: map['location'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      status: map['status'] as String,
    );
  }
}
