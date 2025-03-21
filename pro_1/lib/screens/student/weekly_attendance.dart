import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';

class WeeklyAttendancePage extends StatefulWidget {
  @override
  _WeeklyAttendancePageState createState() => _WeeklyAttendancePageState();
}

class _WeeklyAttendancePageState extends State<WeeklyAttendancePage> {
  DateTime currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  
  // Student data
  String _semester = '';
  String _batch = '';
  String _admissionNo = '';
  
  // Semester details
  DateTime? _semesterStartDate;
  DateTime? _semesterEndDate;
  List<String> _holidays = [];
  String _semesterType = '';
  
  // For timetable and attendance data
  Map<String, Map<String, String>> _timetableData = {};
  Map<String, Map<String, dynamic>> _attendanceData = {};
  
  // NEW: For subject-wise attendance data
  List<Map<String, dynamic>> _subjectAttendance = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isTimetableLoaded = false;
  bool _isAttendanceLoaded = false;
  bool _isSemesterLoaded = false;
  bool _isSubjectAttendanceLoaded = false;
  String _errorMessage = '';

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final List<String> _timeSlots = [
    '9:00 - 10:00',
    '10:05 - 11:05',
    '11:10 - 12:10',
    '1:15 - 2:15',
    '2:20 - 3:20',
    '3:25 - 4:25',
  ];

  // Define color scheme
  final Color primaryColor = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fetch user data from Firebase
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No user logged in';
        });
        return;
      }

      // Get user data from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User profile not found';
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get the semester and batch from user data
      final dynamic semesterRaw = userData['semester'];
      final String semester = semesterRaw is int 
          ? semesterRaw.toString() 
          : (semesterRaw ?? '');
      final String batch = userData['batch'] ?? '';
      final String admissionNo = userData['admissionNo'] ?? '';
      
      setState(() {
        _semester = semester;
        _batch = batch;
        _admissionNo = admissionNo;
      });

      print('User data loaded - Semester: $_semester, Batch: $_batch, AdmissionNo: $_admissionNo');

      // Load semester details first
      await _loadSemesterDetails();
      
      // Now load timetable and attendance data
      await _loadTimetableData();
      await _loadAttendanceData();
      
      // NEW: Load subject-wise attendance data
      await _loadSubjectAttendanceData();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
      print('Error loading user data: $e');
    }
  }

  // Load current semester details
  Future<void> _loadSemesterDetails() async {
    try {
      // Get current semester details
      final semesterDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc('current_semester')
          .get();
      
      if (!semesterDoc.exists) {
        setState(() {
          _isSemesterLoaded = true;
          _errorMessage = 'No current semester details found';
        });
        print('No current semester details found');
        return;
      }

      final data = semesterDoc.data() as Map<String, dynamic>;
      
      // Parse semester details
      final String startDateStr = data['start_date'] ?? '';
      final String endDateStr = data['end_date'] ?? '';
      final List<dynamic> holidaysRaw = data['holidays'] ?? [];
      final String semesterType = data['semester'] ?? '';
      
      // Convert string dates to DateTime objects
      DateTime? startDate;
      DateTime? endDate;
      
      if (startDateStr.isNotEmpty) {
        startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
      }
      
      if (endDateStr.isNotEmpty) {
        endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);
      }
      
      // Convert holidays to List<String>
      List<String> holidays = holidaysRaw.map((h) => h.toString()).toList();
      
      setState(() {
        _semesterStartDate = startDate;
        _semesterEndDate = endDate;
        _holidays = holidays;
        _semesterType = semesterType;
        _isSemesterLoaded = true;
        
        // Adjust the current week if it's outside the semester date range
        if (_semesterStartDate != null && currentWeekStart.isBefore(_semesterStartDate!)) {
          currentWeekStart = _semesterStartDate!;
        }
        
        if (_semesterEndDate != null) {
          // Ensure current week doesn't go beyond the semester end date
          DateTime currentWeekEnd = currentWeekStart.add(Duration(days: 6));
          if (currentWeekEnd.isAfter(_semesterEndDate!)) {
            // Adjust to the last week of the semester
            currentWeekStart = _semesterEndDate!.subtract(Duration(days: _semesterEndDate!.weekday + 6));
            if (currentWeekStart.isBefore(_semesterStartDate!)) {
              currentWeekStart = _semesterStartDate!;
            }
          }
        }
      });
      
      print('Semester details loaded - Start: $_semesterStartDate, End: $_semesterEndDate');
      print('Holidays: $_holidays');
      
    } catch (e) {
      setState(() {
        _isSemesterLoaded = true;
        _errorMessage = 'Error loading semester details: ${e.toString()}';
      });
      print('Error loading semester details: $e');
    }
  }

  // Load timetable data for the student's semester
  Future<void> _loadTimetableData() async {
    if (_semester.isEmpty) {
      setState(() {
        _isTimetableLoaded = true;
        _errorMessage = 'No semester information found';
      });
      return;
    }

    try {
      final timetableDoc = await FirebaseFirestore.instance
          .collection('timetable')
          .doc(_semester)
          .get();
      
      if (!timetableDoc.exists) {
        setState(() {
          _isTimetableLoaded = true;
          _errorMessage = 'No timetable found for semester $_semester';
        });
        return;
      }

      final data = timetableDoc.data() as Map<String, dynamic>;
      
      Map<String, Map<String, String>> timetable = {};
      
      for (String day in _days) {
        if (data.containsKey(day)) {
          timetable[day] = Map<String, String>.from(data[day]);
        } else {
          timetable[day] = {};
          for (String timeSlot in _timeSlots) {
            timetable[day]![timeSlot] = '';
          }
        }
      }
      
      setState(() {
        _timetableData = timetable;
        _isTimetableLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
      });
      
      print('Timetable loaded successfully');
      
    } catch (e) {
      setState(() {
        _isTimetableLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
        _errorMessage = 'Error loading timetable: ${e.toString()}';
      });
      print('Error loading timetable: $e');
    }
  }

  // NEW: Load subject-wise attendance data
  Future<void> _loadSubjectAttendanceData() async {
    if (_semester.isEmpty || _admissionNo.isEmpty) {
      setState(() {
        _isSubjectAttendanceLoaded = true;
        _errorMessage = 'Incomplete student information';
      });
      return;
    }

    try {
      print('Loading subject-wise attendance data for student: $_admissionNo');
      
      List<Map<String, dynamic>> subjectAttendance = await AttendanceService.getStudentSubjectAttendance(
        classId: 'Sem$_semester',
        studentId: _admissionNo,
      );
      
      setState(() {
        _subjectAttendance = subjectAttendance;
        _isSubjectAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
      });
      
      print('Subject attendance loaded successfully: $_subjectAttendance');
      
    } catch (e) {
      setState(() {
        _isSubjectAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
        _errorMessage = 'Error loading subject attendance: ${e.toString()}';
      });
      print('Error loading subject attendance: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_semester.isEmpty || _batch.isEmpty || _admissionNo.isEmpty) {
      setState(() {
        _isAttendanceLoaded = true;
        _errorMessage = 'Incomplete student information';
      });
      print('Incomplete student information. Cannot load attendance.');
      return;
    }

    try {
      print('=========== STARTING ATTENDANCE LOADING ===========');
      print('Loading attendance data for student: $_admissionNo');
      print('Current semester: $_semester, batch: $_batch');
      
      // Get the current week's dates
      List<DateTime> weekDates = List.generate(
        5, 
        (index) => currentWeekStart.add(Duration(days: index))
      );
      
      print('Week dates to check: ${weekDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).join(', ')}');
      
      Map<String, Map<String, dynamic>> attendanceData = {};
      
      // For each date in the week
      for (DateTime date in weekDates) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        String dayName = DateFormat('EEEE').format(date);
        
        print('\nProcessing date: $formattedDate ($dayName)');
        
        if (_days.contains(dayName)) {
          // Create an entry for this date with all periods initially set to null
          List<bool?> periodStatus = List<bool?>.filled(_timeSlots.length, null);
          attendanceData[formattedDate] = {
            'day': dayName,
            'periods': periodStatus,
            'isHoliday': _holidays.contains(formattedDate) // Mark if it's a holiday
          };
          
          // If it's not a holiday, check attendance data
          if (!_holidays.contains(formattedDate)) {
            // Check all documents for this date
            try {
              print('Listing all documents for date $formattedDate:');
              QuerySnapshot dateDocs = await FirebaseFirestore.instance
                  .collection('attendance')
                  .doc('Sem$_semester')
                  .collection(formattedDate)
                  .get();
              
              if (dateDocs.docs.isEmpty) {
                print('No documents found for Sem$_semester/$formattedDate');
              } else {
                print('Found ${dateDocs.docs.length} documents for Sem$_semester/$formattedDate:');
                for (var doc in dateDocs.docs) {
                  print('- ${doc.id}');
                }
              }
            } catch (e) {
              print('Error listing date documents: $e');
            }
            
            // For each period, check if there's attendance data
            for (int periodIndex = 0; periodIndex < _timeSlots.length; periodIndex++) {
              String timeSlot = _timeSlots[periodIndex];
              String subject = _timetableData[dayName]?[timeSlot] ?? '';
              
              if (subject.isNotEmpty) {
                print('\nChecking period: $timeSlot, Subject: $subject');
                
                // Try with the exact format from Firebase
                String docId = '$timeSlot\_$subject';
                print('Trying document ID: $docId');
                
                try {
                  DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
                      .collection('attendance')
                      .doc('Sem$_semester')
                      .collection(formattedDate)
                      .doc(docId)
                      .get();
                      
                  if (attendanceDoc.exists) {
                    print('SUCCESS! Found document with ID: $docId');
                    
                    final data = attendanceDoc.data() as Map<String, dynamic>;
                    
                    // Check if the document contains students data
                    if (data.containsKey('students') && data['students'] is List) {
                      final List<dynamic> students = data['students'] as List<dynamic>;
                      
                      for (var student in students) {
                        if (student is Map && 
                            student.containsKey('studentId') && 
                            student['studentId'] == _admissionNo) {
                          
                          bool isPresent = student['isPresent'];
                          print('Found attendance for student $_admissionNo: $isPresent');
                          
                          // Update the list with the boolean value
                          attendanceData[formattedDate]!['periods'][periodIndex] = isPresent;
                          break;
                        }
                      }
                    }
                  } else {
                    print('No attendance document found for $docId');
                  }
                } catch (e) {
                  print('Error checking document: $e');
                }
              }
            }
          }
        }
      }
      
      setState(() {
        _attendanceData = attendanceData;
        _isAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
      });
      
      print('Final attendance data: $_attendanceData');
      print('=========== FINISHED ATTENDANCE LOADING ===========');
      
    } catch (e) {
      setState(() {
        _isAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded && _isSubjectAttendanceLoaded);
        _errorMessage = 'Error loading attendance: ${e.toString()}';
      });
      print('Error loading attendance: $e');
    }
  }

  // Navigate to previous week
  void _goToPreviousWeek() {
    // Check if the previous week would be before the semester start date
    DateTime previousWeekStart = currentWeekStart.subtract(Duration(days: 7));
    
    if (_semesterStartDate != null && previousWeekStart.isBefore(_semesterStartDate!)) {
      // Set to semester start date
      setState(() {
        currentWeekStart = _semesterStartDate!;
        _isAttendanceLoaded = false;
        _loadAttendanceData();
      });
    } else {
      setState(() {
        currentWeekStart = previousWeekStart;
        _isAttendanceLoaded = false;
        _loadAttendanceData();
      });
    }
  }

  // Navigate to next week
  void _goToNextWeek() {
    // Calculate the end of the current week
    DateTime nextWeekStart = currentWeekStart.add(Duration(days: 7));
    DateTime currentWeekEnd = nextWeekStart.add(Duration(days: 4)); // Friday of next week
    
    // Check if the next week would be after the semester end date
    if (_semesterEndDate != null && currentWeekEnd.isAfter(_semesterEndDate!)) {
      // Don't allow moving past the semester end date
      return;
    }
    
    setState(() {
      currentWeekStart = nextWeekStart;
      _isAttendanceLoaded = false;
      _loadAttendanceData();
    });
  }

  // Build attendance cell
  Widget _buildAttendanceCell(String dateKey, String day, int periodIndex) {
    // Check if this date is a holiday
    bool isHoliday = _attendanceData[dateKey]?['isHoliday'] ?? false;
    
    if (isHoliday) {
      // Return a holiday cell
      return Container(
        color: Colors.amber[100],
        padding: EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              color: Colors.amber[800],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              'Holiday',
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Get the time slot for this period
    String timeSlot = periodIndex < _timeSlots.length ? _timeSlots[periodIndex] : '';
    
    // Check if there's a subject scheduled for this time slot
    String subject = _timetableData[day]?[timeSlot] ?? '';
    
    // If no subject is scheduled, show an empty cell
    if (subject.isEmpty) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Text(
            '-',
            style: GoogleFonts.raleway(
              color: Colors.grey[400],
            ),
          ),
        ),
      );
    }
    
    // Get attendance status for this period
    bool? isPresent = null;
    if (_attendanceData.containsKey(dateKey)) {
      var periods = _attendanceData[dateKey]!['periods'];
      if (periods != null && periodIndex < periods.length) {
        isPresent = periods[periodIndex]; // This should be a boolean or null
      }
    }
    
    // Set colors based on attendance status
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData? statusIcon;
    
    if (isPresent == null) {
      // No attendance data
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
      statusText = 'No Data';
      statusIcon = Icons.remove;
    } else if (isPresent) {
      // Present
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
      statusText = 'Present';
      statusIcon = Icons.check_circle;
    } else {
      // Absent
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      statusText = 'Absent';
      statusIcon = Icons.cancel;
    }
    
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show subject name
          Text(
            subject,
            style: GoogleFonts.raleway(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          // Show status icon
          Icon(
            statusIcon,
            color: textColor,
            size: 20,
          ),
          SizedBox(height: 2),
          // Show status text
          Text(
            statusText,
            style: GoogleFonts.raleway(
              fontSize: 9,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // NEW: Build subject attendance card
  Widget _buildSubjectCard(Map<String, dynamic> subjectData) {
    final String subject = subjectData['subject'] ?? 'Unknown';
    final int markedPeriods = subjectData['markedPeriods'] ?? 0;
    final int presentPeriods = subjectData['presentPeriods'] ?? 0;
    final String percentage = subjectData['percentage'] ?? '0.0';
    
    // Determine color based on percentage
    Color progressColor;
    if (double.parse(percentage) >= 75) {
      progressColor = Colors.green;
    } else if (double.parse(percentage) >= 60) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: markedPeriods > 0 ? presentPeriods / markedPeriods : 0,
                    backgroundColor: Colors.grey[200],
                    color: progressColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Present: $presentPeriods/$markedPeriods classes',
              style: GoogleFonts.raleway(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format semester date range for display
    String semesterDateRange = '';
    if (_semesterStartDate != null && _semesterEndDate != null) {
      semesterDateRange = '${DateFormat('MMM d, yyyy').format(_semesterStartDate!)} - '
                         '${DateFormat('MMM d, yyyy').format(_semesterEndDate!)}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F5E9),  // Light green
                Colors.white,
                Color(0xFFE8F5E9),  // Light green
              ],
            ),
          ),
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
            : _errorMessage.isNotEmpty 
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Add a retry button
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUserData,
                          child: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Weekly Attendance',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Semester $_semester',
                                style: GoogleFonts.raleway(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Batch $_batch',
                                style: GoogleFonts.raleway(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          // Show semester type and date range
                          if (_semesterType.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _semesterType,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          if (semesterDateRange.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                semesterDateRange,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
                                onPressed: _goToPreviousWeek,
                              ),
                              Text(
                                '${DateFormat('MMM d').format(currentWeekStart)} - '
                                '${DateFormat('MMM d').format(currentWeekStart.add(Duration(days: 4)))}',
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF1B5E20)),
                                onPressed: _goToNextWeek,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Show student ID for confirmation
                          Text(
                            'Student ID: $_admissionNo',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          // Add a refresh button
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isAttendanceLoaded = false;
                                _isSubjectAttendanceLoaded = false;
                              });
                              _loadAttendanceData();
                              _loadSubjectAttendanceData();
                            },
                            icon: Icon(Icons.refresh, size: 16, color: Color(0xFF1B5E20)),
                            label: Text(
                              'Refresh Attendance',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Weekly attendance table
                                Table(
                                border: TableBorder.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.8),
                                  1: FlexColumnWidth(1),
                                  2: FlexColumnWidth(1),
                                  3: FlexColumnWidth(1),
                                  4: FlexColumnWidth(1),
                                  5: FlexColumnWidth(1),
                                  6: FlexColumnWidth(1),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1B5E20).withOpacity(0.1),
                                    ),
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Day',
                                            style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      ...List.generate(6, (index) {
                                        return TableCell(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              'Period ${index + 1}',
                                              style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  ..._days.map((day) {
                                    int dayIndex = _days.indexOf(day);
                                    DateTime currentDate = currentWeekStart.add(
                                      Duration(days: dayIndex)
                                    );
                                    String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
                                    
                                    return TableRow(
                                      children: [
                                        TableCell(
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              day.substring(0, 3),
                                              style: GoogleFonts.raleway(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        ...List.generate(6, (periodIndex) {
                                          return TableCell(
                                            child: SizedBox(
                                              height: 70, // Increased height for better visibility
                                              child: _buildAttendanceCell(dateKey, day, periodIndex),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                              
                              // Legend for attendance status
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!, '✓'),
                                    SizedBox(width: 16),
                                    _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!, '✗'),
                                    SizedBox(width: 16),
                                    _buildLegendItem('No Data', Colors.grey[200]!, Colors.grey[600]!, '-'),
                                    SizedBox(width: 16),
                                    _buildLegendItem('Holiday', Colors.amber[100]!, Colors.amber[800]!, 'H'),
                                  ],
                                ),
                              ),
                              
                              // NEW: Subject-wise attendance section
                              SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1B5E20).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.subject, color: Color(0xFF1B5E20)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Subject-Wise Attendance',
                                          style: GoogleFonts.raleway(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Minimum required attendance: 75%',
                                      style: GoogleFonts.raleway(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Subject cards
                              _isSubjectAttendanceLoaded
                                ? _subjectAttendance.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'No subject attendance data available',
                                          style: GoogleFonts.raleway(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _subjectAttendance.length,
                                      separatorBuilder: (context, index) => SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        return _buildSubjectCard(_subjectAttendance[index]);
                                      },
                                    )
                                : Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF1B5E20),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color backgroundColor, Color textColor, String symbol) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: textColor, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 12,
            color: textColor,
          ),
        ),
      ],
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class WeeklyAttendancePage extends StatefulWidget {
//   @override
//   _WeeklyAttendancePageState createState() => _WeeklyAttendancePageState();
// }

// class _WeeklyAttendancePageState extends State<WeeklyAttendancePage> {
//   DateTime currentWeekStart = DateTime.now().subtract(
//     Duration(days: DateTime.now().weekday - 1),
//   );
  
//   // Student data
//   String _semester = '';
//   String _batch = '';
//   String _admissionNo = '';
  
//   // Semester details
//   DateTime? _semesterStartDate;
//   DateTime? _semesterEndDate;
//   List<String> _holidays = [];
//   String _semesterType = '';
  
//   // For timetable and attendance data
//   Map<String, Map<String, String>> _timetableData = {};
//   Map<String, Map<String, dynamic>> _attendanceData = {};
  
//   // Loading states
//   bool _isLoading = true;
//   bool _isTimetableLoaded = false;
//   bool _isAttendanceLoaded = false;
//   bool _isSemesterLoaded = false;
//   String _errorMessage = '';

//   final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
//   final List<String> _timeSlots = [
//     '9:00 - 10:00',
//     '10:05 - 11:05',
//     '11:10 - 12:10',
//     '1:15 - 2:15',
//     '2:20 - 3:20',
//     '3:25 - 4:25',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   // Fetch user data from Firebase
//   Future<void> _loadUserData() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });

//       // Get current user
//       final User? currentUser = FirebaseAuth.instance.currentUser;
      
//       if (currentUser == null) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'No user logged in';
//         });
//         return;
//       }

//       // Get user data from users collection
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();

//       if (!userDoc.exists) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'User profile not found';
//         });
//         return;
//       }

//       final userData = userDoc.data() as Map<String, dynamic>;
      
//       // Get the semester and batch from user data
//       final dynamic semesterRaw = userData['semester'];
//       final String semester = semesterRaw is int 
//           ? semesterRaw.toString() 
//           : (semesterRaw ?? '');
//       final String batch = userData['batch'] ?? '';
//       final String admissionNo = userData['admissionNo'] ?? '';
      
//       setState(() {
//         _semester = semester;
//         _batch = batch;
//         _admissionNo = admissionNo;
//       });

//       print('User data loaded - Semester: $_semester, Batch: $_batch, AdmissionNo: $_admissionNo');

//       // Load semester details first
//       await _loadSemesterDetails();
      
//       // Now load timetable and attendance data
//       await _loadTimetableData();
//       await _loadAttendanceData();
      
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Error loading profile: ${e.toString()}';
//       });
//       print('Error loading user data: $e');
//     }
//   }

//   // Load current semester details
//   Future<void> _loadSemesterDetails() async {
//     try {
//       // Get current semester details
//       final semesterDoc = await FirebaseFirestore.instance
//           .collection('attendance')
//           .doc('current_semester')
//           .get();
      
//       if (!semesterDoc.exists) {
//         setState(() {
//           _isSemesterLoaded = true;
//           _errorMessage = 'No current semester details found';
//         });
//         print('No current semester details found');
//         return;
//       }

//       final data = semesterDoc.data() as Map<String, dynamic>;
      
//       // Parse semester details
//       final String startDateStr = data['start_date'] ?? '';
//       final String endDateStr = data['end_date'] ?? '';
//       final List<dynamic> holidaysRaw = data['holidays'] ?? [];
//       final String semesterType = data['semester'] ?? '';
      
//       // Convert string dates to DateTime objects
//       DateTime? startDate;
//       DateTime? endDate;
      
//       if (startDateStr.isNotEmpty) {
//         startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
//       }
      
//       if (endDateStr.isNotEmpty) {
//         endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);
//       }
      
//       // Convert holidays to List<String>
//       List<String> holidays = holidaysRaw.map((h) => h.toString()).toList();
      
//       setState(() {
//         _semesterStartDate = startDate;
//         _semesterEndDate = endDate;
//         _holidays = holidays;
//         _semesterType = semesterType;
//         _isSemesterLoaded = true;
        
//         // Adjust the current week if it's outside the semester date range
//         if (_semesterStartDate != null && currentWeekStart.isBefore(_semesterStartDate!)) {
//           currentWeekStart = _semesterStartDate!;
//         }
        
//         if (_semesterEndDate != null) {
//           // Ensure current week doesn't go beyond the semester end date
//           DateTime currentWeekEnd = currentWeekStart.add(Duration(days: 6));
//           if (currentWeekEnd.isAfter(_semesterEndDate!)) {
//             // Adjust to the last week of the semester
//             currentWeekStart = _semesterEndDate!.subtract(Duration(days: _semesterEndDate!.weekday + 6));
//             if (currentWeekStart.isBefore(_semesterStartDate!)) {
//               currentWeekStart = _semesterStartDate!;
//             }
//           }
//         }
//       });
      
//       print('Semester details loaded - Start: $_semesterStartDate, End: $_semesterEndDate');
//       print('Holidays: $_holidays');
      
//     } catch (e) {
//       setState(() {
//         _isSemesterLoaded = true;
//         _errorMessage = 'Error loading semester details: ${e.toString()}';
//       });
//       print('Error loading semester details: $e');
//     }
//   }

//   // Load timetable data for the student's semester
//   Future<void> _loadTimetableData() async {
//     if (_semester.isEmpty) {
//       setState(() {
//         _isTimetableLoaded = true;
//         _errorMessage = 'No semester information found';
//       });
//       return;
//     }

//     try {
//       final timetableDoc = await FirebaseFirestore.instance
//           .collection('timetable')
//           .doc(_semester)
//           .get();
      
//       if (!timetableDoc.exists) {
//         setState(() {
//           _isTimetableLoaded = true;
//           _errorMessage = 'No timetable found for semester $_semester';
//         });
//         return;
//       }

//       final data = timetableDoc.data() as Map<String, dynamic>;
      
//       Map<String, Map<String, String>> timetable = {};
      
//       for (String day in _days) {
//         if (data.containsKey(day)) {
//           timetable[day] = Map<String, String>.from(data[day]);
//         } else {
//           timetable[day] = {};
//           for (String timeSlot in _timeSlots) {
//             timetable[day]![timeSlot] = '';
//           }
//         }
//       }
      
//       setState(() {
//         _timetableData = timetable;
//         _isTimetableLoaded = true;
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded);
//       });
      
//       print('Timetable loaded successfully');
      
//     } catch (e) {
//       setState(() {
//         _isTimetableLoaded = true;
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded);
//         _errorMessage = 'Error loading timetable: ${e.toString()}';
//       });
//       print('Error loading timetable: $e');
//     }
//   }

//   Future<void> _loadAttendanceData() async {
//     if (_semester.isEmpty || _batch.isEmpty || _admissionNo.isEmpty) {
//       setState(() {
//         _isAttendanceLoaded = true;
//         _errorMessage = 'Incomplete student information';
//       });
//       print('Incomplete student information. Cannot load attendance.');
//       return;
//     }

//     try {
//       print('=========== STARTING ATTENDANCE LOADING ===========');
//       print('Loading attendance data for student: $_admissionNo');
//       print('Current semester: $_semester, batch: $_batch');
      
//       // Get the current week's dates
//       List<DateTime> weekDates = List.generate(
//         5, 
//         (index) => currentWeekStart.add(Duration(days: index))
//       );
      
//       print('Week dates to check: ${weekDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).join(', ')}');
      
//       Map<String, Map<String, dynamic>> attendanceData = {};
      
//       // For each date in the week
//       for (DateTime date in weekDates) {
//         String formattedDate = DateFormat('yyyy-MM-dd').format(date);
//         String dayName = DateFormat('EEEE').format(date);
        
//         print('\nProcessing date: $formattedDate ($dayName)');
        
//         if (_days.contains(dayName)) {
//           // Create an entry for this date with all periods initially set to null
//           List<bool?> periodStatus = List<bool?>.filled(_timeSlots.length, null);
//           attendanceData[formattedDate] = {
//             'day': dayName,
//             'periods': periodStatus,
//             'isHoliday': _holidays.contains(formattedDate) // Mark if it's a holiday
//           };
          
//           // If it's not a holiday, check attendance data
//           if (!_holidays.contains(formattedDate)) {
//             // Check all documents for this date
//             try {
//               print('Listing all documents for date $formattedDate:');
//               QuerySnapshot dateDocs = await FirebaseFirestore.instance
//                   .collection('attendance')
//                   .doc('Sem$_semester')
//                   .collection(formattedDate)
//                   .get();
              
//               if (dateDocs.docs.isEmpty) {
//                 print('No documents found for Sem$_semester/$formattedDate');
//               } else {
//                 print('Found ${dateDocs.docs.length} documents for Sem$_semester/$formattedDate:');
//                 for (var doc in dateDocs.docs) {
//                   print('- ${doc.id}');
//                 }
//               }
//             } catch (e) {
//               print('Error listing date documents: $e');
//             }
            
//             // For each period, check if there's attendance data
//             for (int periodIndex = 0; periodIndex < _timeSlots.length; periodIndex++) {
//               String timeSlot = _timeSlots[periodIndex];
//               String subject = _timetableData[dayName]?[timeSlot] ?? '';
              
//               if (subject.isNotEmpty) {
//                 print('\nChecking period: $timeSlot, Subject: $subject');
                
//                 // Try with the exact format from Firebase
//                 String docId = '$timeSlot\_$subject';
//                 print('Trying document ID: $docId');
                
//                 try {
//                   DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
//                       .collection('attendance')
//                       .doc('Sem$_semester')
//                       .collection(formattedDate)
//                       .doc(docId)
//                       .get();
                      
//                   if (attendanceDoc.exists) {
//                     print('SUCCESS! Found document with ID: $docId');
                    
//                     final data = attendanceDoc.data() as Map<String, dynamic>;
                    
//                     // Check if the document contains students data
//                     if (data.containsKey('students') && data['students'] is List) {
//                       final List<dynamic> students = data['students'] as List<dynamic>;
                      
//                       for (var student in students) {
//                         if (student is Map && 
//                             student.containsKey('studentId') && 
//                             student['studentId'] == _admissionNo) {
                          
//                           bool isPresent = student['isPresent'];
//                           print('Found attendance for student $_admissionNo: $isPresent');
                          
//                           // Update the list with the boolean value
//                           attendanceData[formattedDate]!['periods'][periodIndex] = isPresent;
//                           break;
//                         }
//                       }
//                     }
//                   } else {
//                     print('No attendance document found for $docId');
//                   }
//                 } catch (e) {
//                   print('Error checking document: $e');
//                 }
//               }
//             }
//           }
//         }
//       }
      
//       setState(() {
//         _attendanceData = attendanceData;
//         _isAttendanceLoaded = true;
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded);
//       });
      
//       print('Final attendance data: $_attendanceData');
//       print('=========== FINISHED ATTENDANCE LOADING ===========');
      
//     } catch (e) {
//       setState(() {
//         _isAttendanceLoaded = true;
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded && _isSemesterLoaded);
//         _errorMessage = 'Error loading attendance: ${e.toString()}';
//       });
//       print('Error loading attendance: $e');
//     }
//   }

//   // Navigate to previous week
//   void _goToPreviousWeek() {
//     // Check if the previous week would be before the semester start date
//     DateTime previousWeekStart = currentWeekStart.subtract(Duration(days: 7));
    
//     if (_semesterStartDate != null && previousWeekStart.isBefore(_semesterStartDate!)) {
//       // Set to semester start date
//       setState(() {
//         currentWeekStart = _semesterStartDate!;
//         _isAttendanceLoaded = false;
//         _loadAttendanceData();
//       });
//     } else {
//       setState(() {
//         currentWeekStart = previousWeekStart;
//         _isAttendanceLoaded = false;
//         _loadAttendanceData();
//       });
//     }
//   }

//   // Navigate to next week
//   void _goToNextWeek() {
//     // Calculate the end of the current week
//     DateTime nextWeekStart = currentWeekStart.add(Duration(days: 7));
//     DateTime currentWeekEnd = nextWeekStart.add(Duration(days: 4)); // Friday of next week
    
//     // Check if the next week would be after the semester end date
//     if (_semesterEndDate != null && currentWeekEnd.isAfter(_semesterEndDate!)) {
//       // Don't allow moving past the semester end date
//       return;
//     }
    
//     setState(() {
//       currentWeekStart = nextWeekStart;
//       _isAttendanceLoaded = false;
//       _loadAttendanceData();
//     });
//   }

//   // Build attendance cell
//   Widget _buildAttendanceCell(String dateKey, String day, int periodIndex) {
//     // Check if this date is a holiday
//     bool isHoliday = _attendanceData[dateKey]?['isHoliday'] ?? false;
    
//     if (isHoliday) {
//       // Return a holiday cell
//       return Container(
//         color: Colors.amber[100],
//         padding: EdgeInsets.all(4),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.event_busy,
//               color: Colors.amber[800],
//               size: 20,
//             ),
//             SizedBox(height: 4),
//             Text(
//               'Holiday',
//               style: GoogleFonts.raleway(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.amber[800],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
    
//     // Get the time slot for this period
//     String timeSlot = periodIndex < _timeSlots.length ? _timeSlots[periodIndex] : '';
    
//     // Check if there's a subject scheduled for this time slot
//     String subject = _timetableData[day]?[timeSlot] ?? '';
    
//     // If no subject is scheduled, show an empty cell
//     if (subject.isEmpty) {
//       return Container(
//         color: Colors.grey[50],
//         child: Center(
//           child: Text(
//             '-',
//             style: GoogleFonts.raleway(
//               color: Colors.grey[400],
//             ),
//           ),
//         ),
//       );
//     }
    
//     // Get attendance status for this period
//     bool? isPresent = null;
//     if (_attendanceData.containsKey(dateKey)) {
//       var periods = _attendanceData[dateKey]!['periods'];
//       if (periods != null && periodIndex < periods.length) {
//         isPresent = periods[periodIndex]; // This should be a boolean or null
//       }
//     }
    
//     // Set colors based on attendance status
//     Color backgroundColor;
//     Color textColor;
//     String statusText;
//     IconData? statusIcon;
    
//     if (isPresent == null) {
//       // No attendance data
//       backgroundColor = Colors.grey[200]!;
//       textColor = Colors.grey[600]!;
//       statusText = 'No Data';
//       statusIcon = Icons.remove;
//     } else if (isPresent) {
//       // Present
//       backgroundColor = Colors.green[100]!;
//       textColor = Colors.green[800]!;
//       statusText = 'Present';
//       statusIcon = Icons.check_circle;
//     } else {
//       // Absent
//       backgroundColor = Colors.red[100]!;
//       textColor = Colors.red[800]!;
//       statusText = 'Absent';
//       statusIcon = Icons.cancel;
//     }
    
//     return Container(
//       color: backgroundColor,
//       padding: EdgeInsets.all(4),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Show subject name
//           Text(
//             subject,
//             style: GoogleFonts.raleway(
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           SizedBox(height: 4),
//           // Show status icon
//           Icon(
//             statusIcon,
//             color: textColor,
//             size: 20,
//           ),
//           SizedBox(height: 2),
//           // Show status text
//           Text(
//             statusText,
//             style: GoogleFonts.raleway(
//               fontSize: 9,
//               color: textColor,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Format semester date range for display
//     String semesterDateRange = '';
//     if (_semesterStartDate != null && _semesterEndDate != null) {
//       semesterDateRange = '${DateFormat('MMM d, yyyy').format(_semesterStartDate!)} - '
//                          '${DateFormat('MMM d, yyyy').format(_semesterEndDate!)}';
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFFE8F5E9),  // Light green
//                 Colors.white,
//                 Color(0xFFE8F5E9),  // Light green
//               ],
//             ),
//           ),
//           child: _isLoading 
//             ? Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
//             : _errorMessage.isNotEmpty 
//               ? Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.error_outline, color: Colors.red, size: 48),
//                         SizedBox(height: 16),
//                         Text(
//                           _errorMessage,
//                           style: GoogleFonts.raleway(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         // Add a retry button
//                         SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _loadUserData,
//                           child: Text('Retry'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFF1B5E20),
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               : Column(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                           Expanded(
//                             child: Text(
//                               'Weekly Attendance',
//                               style: GoogleFonts.playfairDisplay(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                           SizedBox(width: 48),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 'Semester $_semester',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF1B5E20),
//                                 ),
//                               ),
//                               SizedBox(width: 16),
//                               Text(
//                                 'Batch $_batch',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF1B5E20),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           // Show semester type and date range
//                           if (_semesterType.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4.0),
//                               child: Text(
//                                 _semesterType,
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 14,
//                                   fontStyle: FontStyle.italic,
//                                   color: Color(0xFF1B5E20),
//                                 ),
//                               ),
//                             ),
//                           if (semesterDateRange.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4.0),
//                               child: Text(
//                                 semesterDateRange,
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 14,
//                                   color: Color(0xFF1B5E20),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               IconButton(
//                                 icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
//                                 onPressed: _goToPreviousWeek,
//                               ),
//                               Text(
//                                 '${DateFormat('MMM d').format(currentWeekStart)} - '
//                                 '${DateFormat('MMM d').format(currentWeekStart.add(Duration(days: 4)))}',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF1B5E20),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF1B5E20)),
//                                 onPressed: _goToNextWeek,
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 8),
//                           // Show student ID for confirmation
//                           Text(
//                             'Student ID: $_admissionNo',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           // Add a refresh button
//                           TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 _isAttendanceLoaded = false;
//                               });
//                               _loadAttendanceData();
//                             },
//                             icon: Icon(Icons.refresh, size: 16, color: Color(0xFF1B5E20)),
//                             label: Text(
//                               'Refresh Attendance',
//                               style: GoogleFonts.raleway(
//                                 fontSize: 14,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Table(
//                             border: TableBorder.all(
//                               color: Colors.grey[300]!,
//                               width: 1,
//                             ),
//                             columnWidths: const {
//                               0: FlexColumnWidth(0.8),
//                               1: FlexColumnWidth(1),
//                               2: FlexColumnWidth(1),
//                               3: FlexColumnWidth(1),
//                               4: FlexColumnWidth(1),
//                               5: FlexColumnWidth(1),
//                               6: FlexColumnWidth(1),
//                             },
//                             children: [
//                               TableRow(
//                                 decoration: BoxDecoration(
//                                   color: Color(0xFF1B5E20).withOpacity(0.1),
//                                 ),
//                                 children: [
//                                   TableCell(
//                                     child: Padding(
//                                       padding: EdgeInsets.all(8),
//                                       child: Text(
//                                         'Day',
//                                         style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ),
//                                   ),
//                                   ...List.generate(6, (index) {
//                                     return TableCell(
//                                       child: Padding(
//                                         padding: EdgeInsets.all(8),
//                                         child: Text(
//                                           'Period ${index + 1}',
//                                           style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     );
//                                   }),
//                                 ],
//                               ),
//                               ..._days.map((day) {
//                                 int dayIndex = _days.indexOf(day);
//                                 DateTime currentDate = currentWeekStart.add(
//                                   Duration(days: dayIndex)
//                                 );
//                                 String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
                                
//                                 return TableRow(
//                                   children: [
//                                     TableCell(
//                                       child: Container(
//                                         padding: EdgeInsets.all(8),
//                                         child: Text(
//                                           day.substring(0, 3),
//                                           style: GoogleFonts.raleway(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 12,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                     ...List.generate(6, (periodIndex) {
//                                       return TableCell(
//                                         child: SizedBox(
//                                           height: 70, // Increased height for better visibility
//                                           child: _buildAttendanceCell(dateKey, day, periodIndex),
//                                         ),
//                                       );
//                                     }),
//                                   ],
//                                 );
//                               }).toList(),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!, '✓'),
//                           SizedBox(width: 16),
//                           _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!, '✗'),
//                           SizedBox(width: 16),
//                           _buildLegendItem('No Data', Colors.grey[200]!, Colors.grey[600]!, '-'),
//                           SizedBox(width: 16),
//                           _buildLegendItem('Holiday', Colors.amber[100]!, Colors.amber[800]!, 'H'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color backgroundColor, Color textColor, String symbol) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             border: Border.all(color: textColor, width: 1),
//             borderRadius: BorderRadius.circular(2),
//           ),
//           child: Center(
//             child: Text(
//               symbol,
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         SizedBox(width: 4),
//         Text(
//           label,
//           style: GoogleFonts.raleway(
//             fontSize: 12,
//             color: textColor,
//           ),
//         ),
//       ],
//     );
//   }
// }










