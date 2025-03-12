class Student {
  final String id;
  final String name;
  final String classId;

  Student({
    required this.id,
    required this.name,
    required this.classId,
  });

  // Convert Student to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
    };
  }

  // Create Student from Firestore document
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      classId: map['classId'],
    );
  }
}