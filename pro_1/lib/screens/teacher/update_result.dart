import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';

class UpdateResultsPage extends StatefulWidget {
  const UpdateResultsPage({Key? key}) : super(key: key);

  @override
  _UpdateResultsPageState createState() => _UpdateResultsPageState();
}

class _UpdateResultsPageState extends State<UpdateResultsPage> {
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

  // Fetch student data from Firebase directly matching the way bulkupload stores it
  Future<void> _fetchStudentData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print("Starting to fetch student data for results updating...");
      
      // Get reference to Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Initialize data structures
      _semesters = [];
      _semesterBatches = {};
      _studentData = {};
      
      // Check each semester from 1 to 8
      for (int semester = 1; semester <= 8; semester++) {
        print("Checking if Semester $semester exists for results");
        
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
        print("Semester $semester has ${studentsCollection.docs.length} student documents for results");
            
        if (studentsCollection.docs.isEmpty) continue;
        
        // Track batches for this semester
        Map<String, List<Map<String, dynamic>>> batchStudents = {};
        
        // Process each student
        for (var studentDoc in studentsCollection.docs) {
          final studentData = studentDoc.data();
          print("Processing student for results: ${studentData['name']} (${studentDoc.id})");
          
          // Extract batch (removing "Batch " prefix if it exists)
          String batchWithPrefix = studentData['batch'] ?? 'Batch A';
          String batch = batchWithPrefix.replaceAll('Batch ', '');
          
          // Get student result status if available
          // Using null to represent "Not Marked" status
          dynamic resultStatus = studentData.containsKey('isPassed') ? studentData['isPassed'] : null;
          
          // Initialize batch in map if needed
          if (!batchStudents.containsKey(batch)) {
            batchStudents[batch] = [];
          }
          
          // Add student to the batch with result status
          batchStudents[batch]!.add({
            'id': studentData['admissionNo'] ?? studentDoc.id,
            'name': studentData['name'] ?? 'Unknown',
            'email': studentData['email'] ?? studentData['username'] ?? 'Not provided',
            'phone': studentData['phone'] ?? 'Not provided',
            'batch': batch,
            'semester': semester,
            'authUID': studentData['authUID'] ?? '',
            'docId': studentDoc.id, // Store document ID for updates
            'isPassed': resultStatus, // Can be true, false, or null (not marked)
          });
        }
        
        // Update semester data
        _semesterBatches[semester] = batchStudents.keys.toList()..sort();
        _studentData[semester] = batchStudents;
        
        print("Semester $semester has batches for results: ${_semesterBatches[semester]}");
      }
      
      // Sort semesters
      _semesters.sort();
      
      setState(() {
        _isLoading = false;
      });
      
      print("Finished fetching student data for results. Found ${_semesters.length} semesters with students.");
      
    } catch (e) {
      print('Error fetching student data for results: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students for results: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Results',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
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
            onPressed: _fetchStudentData,
            tooltip: 'Refresh student data',
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
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
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
            ElevatedButton.icon(
              onPressed: _fetchStudentData,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Results Management',
          style: GoogleFonts.raleway(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select a semester and batch to update student results',
          style: GoogleFonts.raleway(
            fontSize: 14,
            color: Colors.grey[600],
          ),
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
                    
                    // Calculate unmarked students count
                    int unmarkedCount = 0;
                    if (hasStudents) {
                      unmarkedCount = (_studentData[semester]![batch]!).where(
                        (student) => student['isPassed'] == null
                      ).length;
                    }
                    
                    return ListTile(
                      title: Text(
                        'Batch $batch',
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unmarkedCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Text(
                                '$unmarkedCount unmarked',
                                style: GoogleFonts.raleway(
                                  fontSize: 12,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
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
                                  builder: (context) => ResultsUpdatePage(
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

// Results Update Page to display students and manage pass/fail status
class ResultsUpdatePage extends StatefulWidget {
  final int semester;
  final String batch;
  final List<Map<String, dynamic>> students;
  final VoidCallback onStudentUpdated;

  const ResultsUpdatePage({
    Key? key,
    required this.semester,
    required this.batch,
    required this.students,
    required this.onStudentUpdated,
  }) : super(key: key);

  @override
  _ResultsUpdatePageState createState() => _ResultsUpdatePageState();
}

class _ResultsUpdatePageState extends State<ResultsUpdatePage> {
  late List<Map<String, dynamic>> _students;
  String _searchQuery = '';
  bool _isLoadingAttendance = false;
  Map<String, double> _attendancePercentages = {};
  Map<String, List<Map<String, dynamic>>> _subjectAttendance = {};
  
  // Track student result status changes (null = Not Marked, true = Passed, false = Failed)
  Map<String, dynamic> _studentResults = {};
  // Track which students have unsaved changes
  Set<String> _unsavedChanges = {};
  
  @override
  void initState() {
    super.initState();
    _students = List.from(widget.students);
    // Initialize result status from student data
    for (var student in _students) {
      _studentResults[student['id']] = student['isPassed']; // Can be null, true, or false
    }
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
  
  // Get counts for marking status
  Map<String, int> get _statusCounts {
    int notMarked = 0;
    int passed = 0;
    int failed = 0;
    
    for (var studentId in _studentResults.keys) {
      if (_studentResults[studentId] == null) {
        notMarked++;
      } else if (_studentResults[studentId] == true) {
        passed++;
      } else {
        failed++;
      }
    }
    
    return {
      'notMarked': notMarked,
      'passed': passed,
      'failed': failed,
    };
  }
  
  // Update student result status in Firestore
  Future<void> _updateStudentResult(String studentId, String docId, dynamic resultStatus) async {
    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('classes')
          .doc('Sem${widget.semester}')
          .collection('students')
          .doc(docId)
          .update({'isPassed': resultStatus});
      
      // Update local data
      setState(() {
        _studentResults[studentId] = resultStatus;
        _unsavedChanges.remove(studentId);
        
        // Also update in the main students list
        for (var i = 0; i < _students.length; i++) {
          if (_students[i]['id'] == studentId) {
            _students[i]['isPassed'] = resultStatus;
            break;
          }
        }
      });
      
      String statusMessage;
      if (resultStatus == null) {
        statusMessage = 'marked as Not Marked';
      } else if (resultStatus == true) {
        statusMessage = 'marked as Passed';
      } else {
        statusMessage = 'marked as Failed';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student ID: $studentId $statusMessage'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error updating student result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating result: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Save all unsaved changes
  Future<void> _saveAllChanges() async {
    if (_unsavedChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoadingAttendance = true; // Reuse loading indicator
    });
    
    try {
      // Process each student with unsaved changes
      for (var studentId in _unsavedChanges.toList()) {
        // Find the student in the list
        var student = _students.firstWhere((s) => s['id'] == studentId);
        var docId = student['docId'];
        var resultStatus = _studentResults[studentId];
        
        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('classes')
            .doc('Sem${widget.semester}')
            .collection('students')
            .doc(docId)
            .update({'isPassed': resultStatus});
        
        // Remove from unsaved set
        _unsavedChanges.remove(studentId);
      }
      
      // Update the UI
      setState(() {
        _unsavedChanges.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All results saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Notify parent to refresh
      widget.onStudentUpdated();
    } catch (e) {
      print('Error saving all results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving results: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsavedChanges = _unsavedChanges.isNotEmpty;
    final statusCounts = _statusCounts;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Results: Sem ${widget.semester} - Batch ${widget.batch}',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          if (hasUnsavedChanges)
            IconButton(
              icon: Icon(Icons.save, color: Colors.orange),
              onPressed: _saveAllChanges,
              tooltip: 'Save all changes',
            ),
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
                'Student Results (${_students.length} students)',
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Update status for each student: Not Marked, Passed, or Failed',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              
              // Status summary cards
              Row(
                children: [
                  _buildStatusCard(
                    'Not Marked',
                    statusCounts['notMarked']!,
                    _students.length,
                    Colors.amber,
                    Icons.help_outline,
                  ),
                  SizedBox(width: 8),
                  _buildStatusCard(
                    'Passed',
                    statusCounts['passed']!,
                    _students.length,
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                  SizedBox(width: 8),
                  _buildStatusCard(
                    'Failed',
                    statusCounts['failed']!,
                    _students.length,
                    Colors.red,
                    Icons.cancel_outlined,
                  ),
                ],
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
              
              // Indicators for loading and unsaved changes
              Row(
                children: [
                  if (_isLoadingAttendance) 
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
                            'Loading data...',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (hasUnsavedChanges)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Unsaved changes (${_unsavedChanges.length})',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Spacer(),
                  
                  if (hasUnsavedChanges)
                    ElevatedButton.icon(
                      icon: Icon(Icons.save, size: 16),
                      label: Text('Save All'),
                      onPressed: _saveAllChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 16),
              
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
                          final docId = student['docId'];
                          final hasAttendanceData = _attendancePercentages.containsKey(studentId);
                          final attendancePercentage = _attendancePercentages[studentId] ?? 0.0;
                          final resultStatus = _studentResults[studentId]; // Can be null, true, or false
                          final hasUnsavedChange = _unsavedChanges.contains(studentId);
                          
                          // Determine display variables based on result status
                          Color statusColor;
                          String statusText;
                          IconData statusIcon;
                          
                          if (resultStatus == null) {
                            statusColor = Colors.amber;
                            statusText = 'NOT MARKED';
                            statusIcon = Icons.help_outline;
                          } else if (resultStatus == true) {
                            statusColor = Colors.green;
                            statusText = 'PASSED';
                            statusIcon = Icons.check_circle_outline;
                          } else {
                            statusColor = Colors.red;
                            statusText = 'FAILED';
                            statusIcon = Icons.cancel_outlined;
                          }
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      student['name'] ?? 'Unknown',
                                      style: GoogleFonts.raleway(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Status indicator
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Result status indicator
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: statusColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, size: 12, color: statusColor),
                                            SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: GoogleFonts.raleway(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Unsaved change indicator
                                      if (hasUnsavedChange)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Adm No: ${student['id']}',
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
                                                  0: FlexColumnWidth(3),
                                                  1: FlexColumnWidth(1),
                                                  2: FlexColumnWidth(1),
                                                  3: FlexColumnWidth(1),
                                                },
                                                border: TableBorder.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                                children: [
                                                  TableRow(
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                    ),
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Subject',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Total',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Present',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          '%',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ..._subjectAttendance[studentId]!.map((subject) {
                                                    final subjectName = subject['subjectName'] ?? 'Unknown';
                                                    final totalClasses = subject['totalClasses'] ?? 0;
                                                    final presentClasses = subject['presentClasses'] ?? 0;
                                                    final percentage = totalClasses > 0
                                                        ? (presentClasses / totalClasses * 100)
                                                        : 0.0;
                                                    final attendanceColor = _getAttendanceColor(percentage);
                                                    
                                                    return TableRow(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(subjectName),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            '$totalClasses',
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            '$presentClasses',
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Text(
                                                            '${percentage.toStringAsFixed(1)}%',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              color: attendanceColor,
                                                              fontWeight: FontWeight.w500,
                                                            ),
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
                                      
                                      SizedBox(height: 20),
                                      Text(
                                        'Update Result Status:',
                                        style: GoogleFonts.raleway(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Not Marked Button (Default state)
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.help_outline, size: 16),
                                            label: Text('Not Marked'),
                                            onPressed: () {
                                              // If already not marked, don't update
                                              if (_studentResults[studentId] == null) return;
                                              
                                              setState(() {
                                                // Set to null to represent "Not Marked"
                                                _studentResults[studentId] = null;
                                                // Add to unsaved changes
                                                _unsavedChanges.add(studentId);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: resultStatus == null 
                                                  ? Colors.amber 
                                                  : Colors.grey.shade200,
                                              foregroundColor: resultStatus == null 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                              elevation: resultStatus == null ? 2 : 0,
                                            ),
                                          ),
                                          // Pass Button
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.check_circle_outline, size: 16),
                                            label: Text('Pass'),
                                            onPressed: () {
                                              // If already passed, don't update
                                              if (_studentResults[studentId] == true) return;
                                              
                                              setState(() {
                                                _studentResults[studentId] = true;
                                                _unsavedChanges.add(studentId);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: resultStatus == true 
                                                  ? Colors.green 
                                                  : Colors.grey.shade200,
                                              foregroundColor: resultStatus == true 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                              elevation: resultStatus == true ? 2 : 0,
                                            ),
                                          ),
                                          // Fail Button
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.cancel_outlined, size: 16),
                                            label: Text('Fail'),
                                            onPressed: () {
                                              // If already failed, don't update
                                              if (_studentResults[studentId] == false) return;
                                              
                                              setState(() {
                                                _studentResults[studentId] = false;
                                                _unsavedChanges.add(studentId);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: resultStatus == false 
                                                  ? Colors.red 
                                                  : Colors.grey.shade200,
                                              foregroundColor: resultStatus == false 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                              elevation: resultStatus == false ? 2 : 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      // Save button for individual student
                                      if (hasUnsavedChange)
                                        Center(
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.save, size: 16),
                                            label: Text('Save Changes'),
                                            onPressed: () => _updateStudentResult(
                                              studentId,
                                              docId,
                                              _studentResults[studentId]
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF1B5E20),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
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
      // Add a persistent bottom action bar for saving all changes
      bottomNavigationBar: hasUnsavedChanges
          ? Container(
              color: Colors.orange.shade50,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Text(
                    'You have ${_unsavedChanges.length} unsaved changes',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: _saveAllChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('SAVE ALL'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
  
  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build status summary cards
  Widget _buildStatusCard(String status, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 8),
                Text(
                  status,
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '$count / $total',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to determine attendance color based on percentage
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 65) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
                                                

