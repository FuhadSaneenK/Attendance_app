import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // For timetable and attendance data
  Map<String, Map<String, String>> _timetableData = {};
  Map<String, Map<String, dynamic>> _attendanceData = {};
  
  // Loading states
  bool _isLoading = true;
  bool _isTimetableLoaded = false;
  bool _isAttendanceLoaded = false;
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

      // Now load timetable and attendance data
      await _loadTimetableData();
      await _loadAttendanceData();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
      print('Error loading user data: $e');
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
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
      });
      
      print('Timetable loaded successfully');
      
    } catch (e) {
      setState(() {
        _isTimetableLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
        _errorMessage = 'Error loading timetable: ${e.toString()}';
      });
      print('Error loading timetable: $e');
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
            'periods': periodStatus
          };
          
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
      
      setState(() {
        _attendanceData = attendanceData;
        _isAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
      });
      
      print('Final attendance data: $_attendanceData');
      print('=========== FINISHED ATTENDANCE LOADING ===========');
      
    } catch (e) {
      setState(() {
        _isAttendanceLoaded = true;
        _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
        _errorMessage = 'Error loading attendance: ${e.toString()}';
      });
      print('Error loading attendance: $e');
    }
  }

  // Navigate to previous week
  void _goToPreviousWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
      _isAttendanceLoaded = false;
      _loadAttendanceData();
    });
  }

  // Navigate to next week
  void _goToNextWeek() {
    final now = DateTime.now();
    if (currentWeekStart.isBefore(now)) {
      setState(() {
        currentWeekStart = currentWeekStart.add(Duration(days: 7));
        _isAttendanceLoaded = false;
        _loadAttendanceData();
      });
    }
  }

  // Build attendance cell
  Widget _buildAttendanceCell(String dateKey, String day, int periodIndex) {
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

  @override
  Widget build(BuildContext context) {
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
                      child: Row(
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
                              });
                              _loadAttendanceData();
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
                          child: Table(
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
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!, '✓'),
                          SizedBox(width: 16),
                          _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!, '✗'),
                          SizedBox(width: 16),
                          _buildLegendItem('No Data', Colors.grey[200]!, Colors.grey[600]!, '-'),
                        ],
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


// working connection successfully 
//import 'package:flutter/material.dart';
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
//     Duration(days: DateTime.now().weekday - 1)
//   );
  
//   // Student data
//   String _semester = '';
//   String _batch = '';
//   String _admissionNo = '';
  
//   // For timetable and attendance data
//   Map<String, Map<String, String>> _timetableData = {};
//   Map<String, Map<String, dynamic>> _attendanceData = {};
  
//   // Loading states
//   bool _isLoading = true;
//   bool _isTimetableLoaded = false;
//   bool _isAttendanceLoaded = false;
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
//       final String semester = semesterRaw is int ? semesterRaw.toString() : (semesterRaw ?? '');
//       final String batch = userData['batch'] ?? '';
//       final String admissionNo = userData['admissionNo'] ?? '';
      
//       setState(() {
//         _semester = semester;
//         _batch = batch;
//         _admissionNo = admissionNo;
//       });

//       print('User data loaded - Semester: $_semester, Batch: $_batch, AdmissionNo: $_admissionNo');

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
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
//       });
      
//       print('Timetable loaded successfully');
      
//     } catch (e) {
//       setState(() {
//         _isTimetableLoaded = true;
//         _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
//         _errorMessage = 'Error loading timetable: ${e.toString()}';
//       });
//       print('Error loading timetable: $e');
//     }
//   }

//   // Enhanced debugging method to explore Firestore structure
//   Future<void> _debugFirestoreStructure() async {
//     print('=========== STARTING DEEP FIRESTORE DEBUGGING ===========');

//     try {
//       // First, check the attendance collection
//       print('Checking all documents in attendance collection...');
//       QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
//           .collection('attendance')
//           .get();

//       print('Found ${attendanceSnapshot.docs.length} documents in attendance collection:');
//       for (var doc in attendanceSnapshot.docs) {
//         print('- ${doc.id}');

//         // For each semester document, check its collections
//         try {
//           QuerySnapshot collections = await FirebaseFirestore.instance
//               .collection('attendance')
//               .doc(doc.id)
//               .collection('2025-03-19') // Use a specific date we're trying to find
//               .get();

//           print('  Found ${collections.docs.length} documents in ${doc.id}/2025-03-19:');
//           for (var dateDoc in collections.docs) {
//             print('  - ${dateDoc.id}');
            
//             // Print the actual document data
//             Map<String, dynamic> data = dateDoc.data() as Map<String, dynamic>;
//             print('    Document data: $data');

//             // Check if this document has your student's data
//             if (data.containsKey('students') && data['students'] is List) {
//               for (var student in data['students']) {
//                 if (student['studentId'] == _admissionNo) {
//                   print('    *** FOUND YOUR STUDENT: ${student['studentId']} with isPresent=${student['isPresent']}');
//                 }
//               }
//             }
//           }
//         } catch (e) {
//           print('  Error listing collections for ${doc.id}: $e');
//         }
//       }

//       // Also check original exact path we're trying to access
//       print('\nChecking exact document path we need:');
//       try {
//         DocumentSnapshot specificDoc = await FirebaseFirestore.instance
//             .collection('attendance')
//             .doc('Sem$_semester')
//             .collection('2025-03-19')
//             .doc('10:05 - 11:05_pro')
//             .get();

//         print('Document exists at attendance/Sem$_semester/2025-03-19/10:05 - 11:05_pro: ${specificDoc.exists}');
//         if (specificDoc.exists) {
//           print('Document data: ${specificDoc.data()}');
//         }
//       } catch (e) {
//         print('Error checking exact path: $e');
//       }

//       // Try checking without 'Sem' prefix
//       try {
//         DocumentSnapshot altDoc = await FirebaseFirestore.instance
//             .collection('attendance')
//             .doc(_semester)
//             .collection('2025-03-19')
//             .doc('10:05 - 11:05_pro')
//             .get();

//         print('Document exists at attendance/$_semester/2025-03-19/10:05 - 11:05_pro: ${altDoc.exists}');
//         if (altDoc.exists) {
//           print('Document data: ${altDoc.data()}');
//         }
//       } catch (e) {
//         print('Error checking alternative path: $e');
//       }

//       print('=========== ENDING DEEP FIRESTORE DEBUGGING ===========');
//     } catch (e) {
//       print('Error during deep debugging: $e');
//     }
//   }

// Future<void> _loadAttendanceData() async {
//   if (_semester.isEmpty || _batch.isEmpty || _admissionNo.isEmpty) {
//     setState(() {
//       _isAttendanceLoaded = true;
//       _errorMessage = 'Incomplete student information';
//     });
//     print('Incomplete student information. Cannot load attendance.');
//     return;
//   }

//   try {
//     print('=========== STARTING ATTENDANCE LOADING ===========');
//     print('Loading attendance data for student: $_admissionNo');
//     print('Current semester: $_semester, batch: $_batch');
    
//     // Get the current week's dates
//     List<DateTime> weekDates = List.generate(
//       5, 
//       (index) => currentWeekStart.add(Duration(days: index))
//     );
    
//     print('Week dates to check: ${weekDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).join(', ')}');
    
//     Map<String, Map<String, dynamic>> attendanceData = {};
    
//     // For each date in the week
//     for (DateTime date in weekDates) {
//       String formattedDate = DateFormat('yyyy-MM-dd').format(date);
//       String dayName = DateFormat('EEEE').format(date);
      
//       print('\nProcessing date: $formattedDate ($dayName)');
      
//       if (_days.contains(dayName)) {
//         // Create an entry for this date with all periods initially set to null
//         // Use an array of bool? (nullable booleans) instead of dynamic
//         List<bool?> periodStatus = List<bool?>.filled(_timeSlots.length, null);
//         attendanceData[formattedDate] = {
//           'day': dayName,
//           'periods': periodStatus
//         };
        
//         // Check all documents for this date
//         try {
//           print('Listing all documents for date $formattedDate:');
//           QuerySnapshot dateDocs = await FirebaseFirestore.instance
//               .collection('attendance')
//               .doc('Sem$_semester')
//               .collection(formattedDate)
//               .get();
          
//           if (dateDocs.docs.isEmpty) {
//             print('No documents found for Sem$_semester/$formattedDate');
//           } else {
//             print('Found ${dateDocs.docs.length} documents for Sem$_semester/$formattedDate:');
//             for (var doc in dateDocs.docs) {
//               print('- ${doc.id}');
//             }
//           }
//         } catch (e) {
//           print('Error listing date documents: $e');
//         }
        
//         // For each period, check if there's attendance data
//         for (int periodIndex = 0; periodIndex < _timeSlots.length; periodIndex++) {
//           String timeSlot = _timeSlots[periodIndex];
//           String subject = _timetableData[dayName]?[timeSlot] ?? '';
          
//           if (subject.isNotEmpty) {
//             print('\nChecking period: $timeSlot, Subject: $subject');
            
//             // Try with the exact format from Firebase
//             String docId = '$timeSlot\_$subject';
//             print('Trying document ID: $docId');
            
//             try {
//               DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
//                   .collection('attendance')
//                   .doc('Sem$_semester')
//                   .collection(formattedDate)
//                   .doc(docId)
//                   .get();
                  
//               if (attendanceDoc.exists) {
//                 print('SUCCESS! Found document with ID: $docId');
                
//                 final data = attendanceDoc.data() as Map<String, dynamic>;
                
//                 // Check if the document contains students data
//                 if (data.containsKey('students') && data['students'] is List) {
//                   final List<dynamic> students = data['students'] as List<dynamic>;
                  
//                   for (var student in students) {
//                     if (student is Map && 
//                         student.containsKey('studentId') && 
//                         student['studentId'] == _admissionNo) {
                      
//                       bool isPresent = student['isPresent'];
//                       print('Found attendance for student $_admissionNo: $isPresent');
                      
//                       // FIXED: directly update the list with the boolean value
//                       attendanceData[formattedDate]!['periods'][periodIndex] = isPresent;
//                       break;
//                     }
//                   }
//                 }
//               } else {
//                 print('No attendance document found for $docId');
//               }
//             } catch (e) {
//               print('Error checking document: $e');
//             }
//           }
//         }
//       }
//     }
    
//     setState(() {
//       _attendanceData = attendanceData;
//       _isAttendanceLoaded = true;
//       _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
//     });
    
//     print('Final attendance data: $_attendanceData');
//     print('=========== FINISHED ATTENDANCE LOADING ===========');
    
//   } catch (e) {
//     setState(() {
//       _isAttendanceLoaded = true;
//       _isLoading = !(_isTimetableLoaded && _isAttendanceLoaded);
//       _errorMessage = 'Error loading attendance: ${e.toString()}';
//     });
//     print('Error loading attendance: $e');
//   }
// }

//   // Navigate to previous week
//   void _goToPreviousWeek() {
//     setState(() {
//       currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
//       _isAttendanceLoaded = false;
//       _loadAttendanceData();
//     });
//   }

//   // Navigate to next week
//   void _goToNextWeek() {
//     final now = DateTime.now();
//     if (currentWeekStart.isBefore(now)) {
//       setState(() {
//         currentWeekStart = currentWeekStart.add(Duration(days: 7));
//         _isAttendanceLoaded = false;
//         _loadAttendanceData();
//       });
//     }
//   }

//   // Build attendance cell
//   Widget _buildAttendanceCell(String dateKey, String day, int periodIndex) {
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
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Semester $_semester',
//                             style: GoogleFonts.raleway(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           SizedBox(width: 16),
//                           Text(
//                             'Batch $_batch',
//                             style: GoogleFonts.raleway(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                             ),
//                           ),
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
//                           _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!),
//                           SizedBox(width: 16),
//                           _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!),
//                           SizedBox(width: 16),
//                           _buildLegendItem('No Data', Colors.grey[200]!, Colors.grey[600]!),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color backgroundColor, Color textColor) {
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


// without backend -first setup
//import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'dart:math';

// class WeeklyAttendancePage extends StatefulWidget {
//   @override
//   _WeeklyAttendancePageState createState() => _WeeklyAttendancePageState();
// }

// class _WeeklyAttendancePageState extends State<WeeklyAttendancePage> {
//   DateTime currentWeekStart = DateTime.now().subtract(
//     Duration(days: DateTime.now().weekday - 1)
//   );
  
//   final subjects = {
//     'DS': 'Data Structures',
//     'ALGO': 'Algorithm Design',
//     'WEB': 'Web Development',
//     'NET': 'Computer Networks',
//     'OS': 'Operating Systems',
//     'AI': 'Artificial Intelligence',
//     'DB': 'Database Management',
//     'SE': 'Software Engineering'
//   };

//   final schedule = {
//     'Monday': ['DS', 'ALGO', 'WEB', 'NET', 'OS', 'AI'],
//     'Tuesday': ['AI', 'DB', 'SE', 'DS', 'WEB', 'NET'],
//     'Wednesday': ['OS', 'SE', 'DB', 'ALGO', 'AI', 'DS'],
//     'Thursday': ['WEB', 'NET', 'OS', 'SE', 'DB', 'ALGO'],
//     'Friday': ['DB', 'DS', 'AI', 'WEB', 'NET', 'OS'],
//   };

//   Map<String, Map<String, List<bool>>> sampleAttendance = {};

//   @override
//   void initState() {
//     super.initState();
//     DateTime fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));
//     DateTime current = fourWeeksAgo;
    
//     while (current.isBefore(DateTime.now())) {
//       if (current.weekday <= 5) {
//         String dateKey = DateFormat('yyyy-MM-dd').format(current);
//         sampleAttendance[dateKey] = {
//           'attendance': List.generate(6, (index) => Random().nextBool())
//         };
//       }
//       current = current.add(Duration(days: 1));
//     }
//   }

//   String _getTimeSlot(int periodIndex) {
//     switch (periodIndex) {
//       case 0: return '9:00 - 10:00';
//       case 1: return '10:05 - 11:05';
//       case 2: return '11:10 - 12:10';
//       case 3: return '1:15 - 2:15';
//       case 4: return '2:20 - 3:20';
//       case 5: return '3:25 - 4:25';
//       default: return '';
//     }
//   }

//   Widget _buildAttendanceCell(String day, int periodIndex, bool? isPresent) {
//     String subject = schedule[day]![periodIndex];
//     String timeSlot = _getTimeSlot(periodIndex);
    
//     return Container(
//       margin: EdgeInsets.all(2),
//       decoration: BoxDecoration(
//         color: isPresent == null 
//           ? Colors.grey[200]
//           : (isPresent ? Colors.green[100] : Colors.red[100]),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(4),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               subject,
//               style: GoogleFonts.raleway(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 2),
//             Text(
//               timeSlot,
//               style: GoogleFonts.raleway(
//                 fontSize: 10,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
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
//           child: Column(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     Expanded(
//                       child: Text(
//                         'Weekly Attendance',
//                         style: GoogleFonts.playfairDisplay(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1B5E20),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     SizedBox(width: 48),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
//                       onPressed: () {
//                         setState(() {
//                           currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
//                         });
//                       },
//                     ),
//                     Text(
//                       '${DateFormat('MMM d').format(currentWeekStart)} - '
//                       '${DateFormat('MMM d').format(currentWeekStart.add(Duration(days: 4)))}',
//                       style: GoogleFonts.raleway(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1B5E20),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF1B5E20)),
//                       onPressed: () {
//                         if (currentWeekStart.isBefore(DateTime.now())) {
//                           setState(() {
//                             currentWeekStart = currentWeekStart.add(Duration(days: 7));
//                           });
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Table(
//                       border: TableBorder.all(
//                         color: Colors.grey[300]!,
//                         width: 1,
//                       ),
//                       columnWidths: const {
//                         0: FlexColumnWidth(0.8),
//                         1: FlexColumnWidth(1),
//                         2: FlexColumnWidth(1),
//                         3: FlexColumnWidth(1),
//                         4: FlexColumnWidth(1),
//                         5: FlexColumnWidth(1),
//                         6: FlexColumnWidth(1),
//                       },
//                       children: [
//                         TableRow(
//                           decoration: BoxDecoration(
//                             color: Color(0xFF1B5E20).withOpacity(0.1),
//                           ),
//                           children: [
//                             TableCell(
//                               child: Padding(
//                                 padding: EdgeInsets.all(8),
//                                 child: Text(
//                                   'Day',
//                                   style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             ),
//                             ...List.generate(6, (index) {
//                               return TableCell(
//                                 child: Padding(
//                                   padding: EdgeInsets.all(8),
//                                   child: Text(
//                                     'Period ${index + 1}',
//                                     style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ),
//                               );
//                             }),
//                           ],
//                         ),
//                         ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
//                           return TableRow(
//                             children: [
//                               TableCell(
//                                 child: Container(
//                                   padding: EdgeInsets.all(8),
//                                   child: Text(
//                                     day.substring(0, 3),
//                                     style: GoogleFonts.raleway(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 12,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ),
//                               ),
//                               ...List.generate(6, (periodIndex) {
//                                 DateTime currentDate = currentWeekStart.add(
//                                   Duration(days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].indexOf(day))
//                                 );
//                                 String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
//                                 bool? attendance = sampleAttendance[dateKey]?['attendance']?[periodIndex];
                                
//                                 return TableCell(
//                                   child: SizedBox(
//                                     height: 60,
//                                     child: _buildAttendanceCell(day, periodIndex, attendance),
//                                   ),
//                                 );
//                               }),
//                             ],
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!),
//                     SizedBox(width: 16),
//                     _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color backgroundColor, Color iconColor) {
//     return Row(
//       children: [
//         Container(
//           width: 24,
//           height: 24,
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Icon(
//             label == 'Present' ? Icons.check : Icons.close,
//             color: iconColor,
//             size: 16,
//           ),
//         ),
//         SizedBox(width: 8),
//         Text(
//           label,
//           style: GoogleFonts.raleway(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }