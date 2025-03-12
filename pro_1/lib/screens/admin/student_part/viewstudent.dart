import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentListPage extends StatelessWidget {
  final List<String> departments;

  const StudentListPage({Key? key, required this.departments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for students (would come from your database)
    final Map<String, Map<String, List<Map<String, dynamic>>>> studentData = {
      'Computer Science': {
        '1st Year': [
          {'id': 'CS001', 'name': 'John Doe', 'phone': '1234567890', 'email': 'john.doe@example.com', 'attendance': 92.5},
          {'id': 'CS002', 'name': 'Jane Smith', 'phone': '9876543210', 'email': 'jane.smith@example.com', 'attendance': 88.0},
        ],
        '2nd Year': [
          {'id': 'CS101', 'name': 'Alex Johnson', 'phone': '5556667777', 'email': 'alex.j@example.com', 'attendance': 95.0},
        ],
      },
      'Electrical Engineering': {
        '1st Year': [
          {'id': 'EE001', 'name': 'Emily Clark', 'phone': '1122334455', 'email': 'emily.c@example.com', 'attendance': 91.2},
        ],
      },
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by Department',
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    department,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  children: ['1st Year', '2nd Year'].map((year) {
                    final hasStudents = studentData[department]?[year]?.isNotEmpty ?? false;
                    return ListTile(
                      title: Text(
                        year,
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      enabled: hasStudents,
                      onTap: hasStudents
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailPage(
                                    department: department,
                                    year: year,
                                    students: studentData[department]?[year] ?? [],
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Student Detail Page to display students by department and year
class StudentDetailPage extends StatelessWidget {
  final String department;
  final String year;
  final List<Map<String, dynamic>> students;

  const StudentDetailPage({
    Key? key,
    required this.department,
    required this.year,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$department - $year',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 223, 243, 225),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student List',
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          student['name'],
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${student['id']}',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow('Phone', student['phone']),
                                _buildDetailRow('Email', student['email']),
                                _buildDetailRow(
                                  'Attendance',
                                  '${student['attendance']}%',
                                  valueColor: _getAttendanceColor(student['attendance']),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.raleway(
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 90) {
      return Colors.green;
    } else if (attendance >= 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}