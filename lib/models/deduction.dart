class Deduction {
  final int? id;
  final int employeeId;
  final String date;
  final double amount;
  final String reason;
  final int approvedBy;
  final String status;
  final int? executedBy;

  Deduction({
    this.id,
    required this.employeeId,
    required this.date,
    required this.amount,
    required this.reason,
    required this.approvedBy,
    this.status = 'pending',
    this.executedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'date': date,
      'amount': amount,
      'reason': reason,
      'approved_by': approvedBy,
      'status': status,
      'executed_by': executedBy,
    };
  }

  factory Deduction.fromMap(Map<String, dynamic> map) {
    return Deduction(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      date: map['date'] as String,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String,
      approvedBy: map['approved_by'] as int,
      status: map['status'] as String,
      executedBy: map['executed_by'] as int?,
    );
  }
}
