import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherListPage extends StatelessWidget {
  final String department;
  final List<Map<String, dynamic>> teachers;

  const TeacherListPage({
    Key? key,
    required this.department,
    required this.teachers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$department Teachers',
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
                'Teacher List',
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          teacher['name'],
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${teacher['position']}',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('ID', teacher['id']),
                                _buildDetailRow('Email', teacher['email']),
                                _buildDetailRow('Phone', teacher['phone']),
                                _buildDetailRow('Specialization', 
                                  teacher['specialization'] ?? 'Not specified'
                                ),
                                _buildResearchInterests(teacher['researchInterests'] ?? []),
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

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchInterests(List<dynamic> interests) {
    if (interests.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Research Interests:',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: interests.map((interest) => Chip(
              label: Text(
                interest,
                style: GoogleFonts.raleway(fontSize: 12),
              ),
              backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ),
    );
  }
}