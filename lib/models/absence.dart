class Absence {
  final int? id;
  final int employeeId;
  final String date;
  final String type;
  final String? reason;
  final int? verifiedBy;
  final int? deductionDecisionId;

  Absence({
    this.id,
    required this.employeeId,
    required this.date,
    required this.type,
    this.reason,
    this.verifiedBy,
    this.deductionDecisionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'date': date,
      'type': type,
      'reason': reason,
      'verified_by': verifiedBy,
      'deduction_decision_id': deductionDecisionId,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      date: map['date'] as String,
      type: map['type'] as String,
      reason: map['reason'] as String?,
      verifiedBy: map['verified_by'] as int?,
      deductionDecisionId: map['deduction_decision_id'] as int?,
    );
  }
}
