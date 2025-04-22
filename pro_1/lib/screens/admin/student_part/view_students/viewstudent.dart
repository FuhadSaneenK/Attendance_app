import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the student operations file
import 'package:pro_1/screens/admin/student_part/view_students/edit_student.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';
// Import the attendance service


class StudentListPage extends StatefulWidget {
  const StudentListPage({Key? key}) : super(key: key);

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // Loading state
  bool _isLoading = true;
  
  // Store semesters and student data
  List<int> _semesters = [];
  Map<int, List<String>> _semesterBatches = {};
  Map<int, Map<String, List<Map<String, dynamic>>>> _studentData = {};

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }
  
  // Helper method to load dummy data for testing
  Future<void> _loadDummyData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Create dummy data for semester 1 and batch A
      _semesters = [1];
      _semesterBatches = {
        1: ['A'],
      };
      _studentData = {
        1: {
          'A': [
            {
              'id': 'CS001',
              'name': 'John Smith',
              'email': 'CS001@gmail.com',
              'phone': '9876543210',
              'batch': 'A',
              'semester': 1,
              'attendance': 93.5,
              'authUID': 'dummy-uid-1',
            },
            {
              'id': 'CS002',
              'name': 'Mary Johnson',
              'email': 'CS002@gmail.com',
              'phone': '8765432109',
              'batch': 'A',
              'semester': 1,
              'attendance': 87.2,
              'authUID': 'dummy-uid-2',
            },
          ],
        },
      };
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test data loaded successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading test data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch student data from Firebase directly matching the way bulkupload stores it
  Future<void> _fetchStudentData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print("Starting to fetch student data from Firebase...");
      
      // Get reference to Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Create a hardcoded list of possible semesters since we know the structure
      _semesters = [];
      
      // Initialize data structures
      _semesterBatches = {};
      _studentData = {};
      
      // Check each semester from 1 to 8
      for (int semester = 1; semester <= 8; semester++) {
        print("Checking if Semester $semester exists");
        
        // Create a reference to the semester document
        final semesterRef = firestore.collection('classes').doc('Sem$semester');
        
        // Check if the semester document exists
        final semesterDoc = await semesterRef.get();
        if (!semesterDoc.exists) {
          print("Semester $semester document doesn't exist");
          continue;
        }
        
        // If we reach here, this semester exists
        _semesters.add(semester);
        
        // Initialize semester in data structures
        _semesterBatches[semester] = [];
        _studentData[semester] = {};
        
        // Get all students in this semester
        final studentsCollection = await semesterRef.collection('students').get();
        print("Semester $semester has ${studentsCollection.docs.length} student documents");
            
        if (studentsCollection.docs.isEmpty) continue;
        
        // Track batches for this semester
        Map<String, List<Map<String, dynamic>>> batchStudents = {};
        
        // Process each student
        for (var studentDoc in studentsCollection.docs) {
          final studentData = studentDoc.data();
          print("Processing student: ${studentData['name']} (${studentDoc.id})");
          
          // Extract batch (removing "Batch " prefix if it exists)
          String batchWithPrefix = studentData['batch'] ?? 'Batch A';
          String batch = batchWithPrefix.replaceAll('Batch ', '');
          
          print("Student batch: $batch (original: $batchWithPrefix)");
          
          // Initialize batch in map if needed
          if (!batchStudents.containsKey(batch)) {
            batchStudents[batch] = [];
          }
          
          // Add student to the batch
          batchStudents[batch]!.add({
            'id': studentData['admissionNo'] ?? studentDoc.id,
            'name': studentData['name'] ?? 'Unknown',
            'email': studentData['email'] ?? studentData['username'] ?? 'Not provided',
            'phone': studentData['phone'] ?? 'Not provided',
            'batch': batch,
            'semester': semester,
            'authUID': studentData['authUID'] ?? '',
          });
          
          print("Added student ${studentData['name']} to batch $batch");
        }
        
        // Update semester data
        _semesterBatches[semester] = batchStudents.keys.toList()..sort();
        _studentData[semester] = batchStudents;
        
        print("Semester $semester has batches: ${_semesterBatches[semester]}");
        
        // Print count of students in each batch for debugging
        batchStudents.forEach((batch, students) {
          print("Batch $batch has ${students.length} students");
        });
      }
      
      // Sort semesters
      _semesters.sort();
      
      setState(() {
        _isLoading = false;
      });
      
      print("Finished fetching student data. Found ${_semesters.length} semesters with students.");
      
      // If no students found, load demo data
      if (_semesters.isEmpty) {
        print("No students found in any semester. Consider using the 'Load Test Data' button.");
      }
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Loading students...',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_semesters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'No student data available',
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchStudentData,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadDummyData,
                  icon: Icon(Icons.admin_panel_settings),
                  label: Text('Load Test Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Directory',
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchStudentData,
              color: Color(0xFF1B5E20),
              tooltip: 'Refresh student data',
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _semesters.length,
            itemBuilder: (context, index) {
              final semester = _semesters[index];
              final batches = _semesterBatches[semester] ?? [];
              
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    'Semester $semester',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  children: batches.map((batch) {
                    final hasStudents = 
                        (_studentData[semester]?[batch]?.isNotEmpty ?? false);
                    
                    // Debug info about this batch
                    print("Batch $batch in Semester $semester has ${_studentData[semester]?[batch]?.length ?? 0} students");
                    
                    return ListTile(
                      title: Text(
                        'Batch $batch',
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_studentData[semester]?[batch]?.length ?? 0} students',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      enabled: hasStudents,
                      onTap: hasStudents
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailPage(
                                    semester: semester,
                                    batch: batch,
                                    students: _studentData[semester]?[batch] ?? [],
                                    onStudentUpdated: () {
                                      // Refresh the data when returning from detail page
                                      _fetchStudentData();
                                    },
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
        ),
      ],
    );
  }
}

// Student Detail Page to display students by semester and batch
class StudentDetailPage extends StatefulWidget {
  final int semester;
  final String batch;
  final List<Map<String, dynamic>> students;
  final VoidCallback onStudentUpdated;

  const StudentDetailPage({
    Key? key,
    required this.semester,
    required this.batch,
    required this.students,
    required this.onStudentUpdated,
  }) : super(key: key);

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late List<Map<String, dynamic>> _students;
  String _searchQuery = '';
  bool _isLoadingAttendance = false;
  Map<String, double> _attendancePercentages = {};
  Map<String, List<Map<String, dynamic>>> _subjectAttendance = {};
  
  @override
  void initState() {
    super.initState();
    _students = List.from(widget.students);
    _fetchAttendanceData();
  }
  
  // Fetch attendance data for all students
  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoadingAttendance = true;
    });
    
    try {
      // Get attendance for each student
      for (var student in _students) {
        final String studentId = student['id'];
        
        // Get overall attendance percentage
        final attendanceData = await AttendanceService.getStudentAttendanceCounters(
          classId: 'Sem${widget.semester}',
          studentId: studentId,
        );
        
        int markedPeriods = attendanceData['markedPeriods'] ?? 0;
        int presentPeriods = attendanceData['presentPeriods'] ?? 0;
        
        double percentage = markedPeriods > 0 
            ? (presentPeriods / markedPeriods * 100) 
            : 0.0;
        
        // Get subject-wise attendance
        final subjectData = await AttendanceService.getStudentSubjectAttendance(
          classId: 'Sem${widget.semester}',
          studentId: studentId,
        );
        
        setState(() {
          _attendancePercentages[studentId] = percentage;
          _subjectAttendance[studentId] = subjectData;
        });
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }
  
  // Filter students based on search query
  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    
    final query = _searchQuery.toLowerCase();
    return _students.where((student) {
      final name = (student['name'] as String).toLowerCase();
      final id = (student['id'] as String).toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Semester ${widget.semester} - Batch ${widget.batch}',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAttendanceData,
            tooltip: 'Refresh attendance data',
          ),
        ],
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
                'Student List (${_students.length} students)',
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or admission number',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 16),
              _isLoadingAttendance 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Loading attendance data...',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              Expanded(
                child: _filteredStudents.isEmpty 
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'No students found in this batch'
                              : 'No students match your search',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          final studentId = student['id'];
                          final hasAttendanceData = _attendancePercentages.containsKey(studentId);
                          final attendancePercentage = _attendancePercentages[studentId] ?? 0.0;
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                student['name'] ?? 'Unknown',
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Adm No: ${student['id']}',
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                ),
                              ),
                              trailing: hasAttendanceData
                                  ? Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getAttendanceColor(attendancePercentage).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getAttendanceColor(attendancePercentage),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${attendancePercentage.toStringAsFixed(1)}%',
                                        style: GoogleFonts.raleway(
                                          fontWeight: FontWeight.w600,
                                          color: _getAttendanceColor(attendancePercentage),
                                        ),
                                      ),
                                    )
                                  : null,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Email', student['email'] ?? 'Not provided'),
                                      _buildDetailRow('Phone', student['phone'] ?? 'Not provided'),
                                      if (hasAttendanceData)
                                        _buildDetailRow(
                                          'Overall Attendance',
                                          '${attendancePercentage.toStringAsFixed(1)}%',
                                          valueColor: _getAttendanceColor(attendancePercentage),
                                        ),
                                      
                                      // Subject-wise attendance
                                      if (_subjectAttendance.containsKey(studentId) && 
                                          _subjectAttendance[studentId]!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Subject-wise Attendance:',
                                                style: GoogleFonts.raleway(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Table(
                                                columnWidths: {
                                                  0: FlexColumnWidth(2),
                                                  1: FlexColumnWidth(1),
                                                },
                                                children: [
                                                  TableRow(
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                    ),
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                        child: Text(
                                                          'Subject',
                                                          style: GoogleFonts.raleway(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                        child: Text(
                                                          'Attendance',
                                                          style: GoogleFonts.raleway(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          textAlign: TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ..._subjectAttendance[studentId]!.map((subject) {
                                                    double percentage = double.tryParse(subject['percentage']) ?? 0.0;
                                                    return TableRow(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                          child: Text(
                                                            subject['subject'],
                                                            style: GoogleFonts.raleway(),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                          child: Text(
                                                            '${subject['percentage']}%',
                                                            style: GoogleFonts.raleway(
                                                              color: _getAttendanceColor(percentage),
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            textAlign: TextAlign.right,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: Icon(Icons.edit, size: 18),
                                            label: Text('Edit'),
                                            onPressed: () async {
                                              // Call the edit function from StudentOperations
                                              bool updated = await StudentOperations.editStudent(
                                                context: context,
                                                student: student,
                                                semester: widget.semester,
                                                batch: widget.batch,
                                              );
                                              
                                              // If student was updated successfully, refresh data
                                              if (updated) {
                                                widget.onStudentUpdated();
                                                Navigator.pop(context);
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Color(0xFF1B5E20),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          TextButton.icon(
                                            icon: Icon(Icons.delete_outline, size: 18),
                                            label: Text('Remove'),
                                            onPressed: () async {
                                              // Call the remove function from StudentOperations
                                              bool removed = await StudentOperations.removeStudent(
                                                context: context,
                                                student: student,
                                                semester: widget.semester,
                                                batch: widget.batch,
                                              );
                                              
                                              // If student was removed successfully, refresh data
                                              if (removed) {
                                                // Update local list first for immediate UI feedback
                                                setState(() {
                                                  _students.removeWhere((s) => s['id'] == student['id']);
                                                });
                                                
                                                // Then notify parent to refresh data from Firebase
                                                widget.onStudentUpdated();
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
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
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
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
