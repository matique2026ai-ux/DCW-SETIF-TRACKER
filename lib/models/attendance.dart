class Attendance {
  final int? id;
  final int employeeId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final bool isCheckedOut;
  final String? photo;

  Attendance({
    this.id,
    required this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.isCheckedOut = false,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'date': date,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'is_checked_out': isCheckedOut ? 1 : 0,
      'photo': photo,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      date: map['date'] as String,
      checkInTime: map['check_in_time'] as String?,
      checkOutTime: map['check_out_time'] as String?,
      checkInLocation: map['check_in_location'] as String?,
      checkOutLocation: map['check_out_location'] as String?,
      isCheckedOut: map['is_checked_out'] == 1,
      photo: map['photo'] as String?,
    );
  }
}
