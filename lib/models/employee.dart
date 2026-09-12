class Employee {
  final int? id;
  final String matricule;
  final String name;
  final String firstName;
  final String rank;
  final String department;
  final String position;
  final double salary;
  final bool isActive;

  Employee({
    this.id,
    required this.matricule,
    required this.name,
    required this.firstName,
    required this.rank,
    required this.department,
    required this.position,
    required this.salary,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'matricule': matricule,
      'name': name,
      'first_name': firstName,
      'rank': rank,
      'department': department,
      'position': position,
      'salary': salary,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      matricule: map['matricule'] as String,
      name: map['name'] as String,
      firstName: map['first_name'] as String,
      rank: map['rank'] as String,
      department: map['department'] as String,
      position: map['position'] as String,
      salary: (map['salary'] as num).toDouble(),
      isActive: map['is_active'] == 1,
    );
  }
}
