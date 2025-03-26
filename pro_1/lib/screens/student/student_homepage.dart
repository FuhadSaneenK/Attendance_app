import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pro_1/screens/student/viewannouncement.dart';
import 'package:pro_1/screens/student/student%20profile/student_profile.dart';
import 'package:pro_1/screens/student/support.dart';
import 'package:pro_1/screens/student/view_timetable.dart';
import 'package:pro_1/screens/student/weekly_attendance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';
import 'package:pro_1/user_select.dart';
import 'package:intl/intl.dart';
// Import the attendance service

class StudentHomePage extends StatefulWidget {
  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String studentName = "Student";
  String studentInitial = "S";
  double attendancePercentage = 0.0;
  bool isLoading = true;
  
  // Student data
  String _semester = '';
  String _batch = '';
  String _admissionNo = '';
  
  // Attendance counters
  int _markedPeriods = 0;
  int _presentPeriods = 0;
  
  // Semester details
  DateTime? _semesterStartDate;
  DateTime? _semesterEndDate;
  List<String> _holidays = [];
  String _semesterType = '';
  
  // For timetable data
  Map<String, Map<String, String>> _timetableData = {};
  
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
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final User? user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Get user data from users collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Get the semester, batch and admission number from user data
        final dynamic semesterRaw = userData['semester'];
        final String semester = semesterRaw is int 
            ? semesterRaw.toString() 
            : (semesterRaw ?? '');
        final String batch = userData['batch'] ?? '';
        final String admissionNo = userData['admissionNo'] ?? '';
        final String name = userData['name'] ?? 'Student';
        
        setState(() {
          studentName = name;
          studentInitial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
          _semester = semester;
          _batch = batch;
          _admissionNo = admissionNo;
        });

        print('User data loaded - Semester: $_semester, Batch: $_batch, AdmissionNo: $_admissionNo');

        // Load semester details and get attendance data
        await _loadSemesterDetails();
        await _loadTimetableData();
        await _loadAttendanceData();
      } else {
        // No user is signed in, redirect to login
        setState(() {
          isLoading = false;
        });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => UserSelectionPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        isLoading = false;
      });
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
      });
      
      print('Semester details loaded - Start: $_semesterStartDate, End: $_semesterEndDate');
      print('Holidays: $_holidays');
      
    } catch (e) {
      print('Error loading semester details: $e');
    }
  }

  // Load timetable data for the student's semester
  Future<void> _loadTimetableData() async {
    if (_semester.isEmpty) {
      return;
    }

    try {
      final timetableDoc = await FirebaseFirestore.instance
          .collection('timetable')
          .doc(_semester)
          .get();
      
      if (!timetableDoc.exists) {
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
      });
      
      print('Timetable loaded successfully');
      
    } catch (e) {
      print('Error loading timetable: $e');
    }
  }

  // New method to load attendance data using the counters
  Future<void> _loadAttendanceData() async {
    if (_semester.isEmpty || _admissionNo.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      print('Loading attendance counters for student: $_admissionNo in semester: $_semester');
      
      // Get attendance counters from the new system
      final attendanceData = await AttendanceService.getStudentAttendanceCounters(
        classId: 'Sem$_semester',
        studentId: _admissionNo,
      );
      
      int markedPeriods = attendanceData['markedPeriods'] ?? 0;
      int presentPeriods = attendanceData['presentPeriods'] ?? 0;
      
      // Calculate attendance percentage
      double percentage = markedPeriods > 0 ? (presentPeriods / markedPeriods) : 0.0;
      
      setState(() {
        _markedPeriods = markedPeriods;
        _presentPeriods = presentPeriods;
        attendancePercentage = percentage;
        isLoading = false;
      });
      
      print('Attendance calculation (using counters): $presentPeriods/$markedPeriods = ${(percentage * 100).toStringAsFixed(2)}%');
      
    } catch (e) {
      // Fallback to old calculation method if the counter system fails
      print('Error loading attendance counters: $e');
      print('Falling back to legacy calculation method...');
      await _calculateAttendancePercentage();
    }
  }

  // Legacy calculation method (kept as fallback)
  Future<void> _calculateAttendancePercentage() async {
    if (_semester.isEmpty || _batch.isEmpty || _admissionNo.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      print('Calculating attendance percentage for student: $_admissionNo');
      
      // If the semester has start and end dates, use those for date range
      DateTime startDate = _semesterStartDate ?? DateTime.now().subtract(Duration(days: 90));
      DateTime endDate = _semesterEndDate ?? DateTime.now();
      
      // List to store all the dates to check
      List<DateTime> allDates = [];
      
      // Generate all weekdays (Monday to Friday) in the date range
      DateTime current = startDate;
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        // Only add days from Monday (1) to Friday (5)
        if (current.weekday >= 1 && current.weekday <= 5) {
          allDates.add(current);
        }
        current = current.add(Duration(days: 1));
      }
      
      int totalPeriods = 0;
      int presentPeriods = 0;
      
      // For each date
      for (DateTime date in allDates) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        String dayName = DateFormat('EEEE').format(date);
        
        // Skip holidays
        if (_holidays.contains(formattedDate)) {
          continue;
        }
        
        // For each period in the day
        for (int periodIndex = 0; periodIndex < _timeSlots.length; periodIndex++) {
          String timeSlot = _timeSlots[periodIndex];
          String subject = _timetableData[dayName]?[timeSlot] ?? '';
          
          // Skip if no subject scheduled
          if (subject.isEmpty) {
            continue;
          }
          
          // Format the document ID in the same way as WeeklyAttendancePage
          String docId = '$timeSlot\_$subject';
          
          try {
            DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
                .collection('attendance')
                .doc('Sem$_semester')
                .collection(formattedDate)
                .doc(docId)
                .get();
                
            if (attendanceDoc.exists) {
              final data = attendanceDoc.data() as Map<String, dynamic>;
              
              // Check if the document contains students data
              if (data.containsKey('students') && data['students'] is List) {
                final List<dynamic> students = data['students'] as List<dynamic>;
                
                // Count this as a scheduled period regardless of attendance
                totalPeriods++;
                
                for (var student in students) {
                  if (student is Map && 
                      student.containsKey('studentId') && 
                      student['studentId'] == _admissionNo) {
                    
                    bool isPresent = student['isPresent'];
                    if (isPresent) {
                      presentPeriods++;
                    }
                    break;
                  }
                }
              }
            }
          } catch (e) {
            print('Error checking attendance: $e');
          }
        }
      }
      
      // Calculate attendance percentage
      double percentage = totalPeriods > 0 ? (presentPeriods / totalPeriods) : 0.0;
      
      setState(() {
        _markedPeriods = totalPeriods;
        _presentPeriods = presentPeriods;
        attendancePercentage = percentage;
        isLoading = false;
      });
      
      print('Attendance calculation (legacy method): $presentPeriods/$totalPeriods = ${(percentage * 100).toStringAsFixed(2)}%');
      
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error calculating attendance: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => UserSelectionPage()),
        (route) => false,
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1B5E20),
          ),
        ),
      );
    }
    
    return Scaffold(
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Container(
          height: screenSize.height,
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
          child: Column(
            children: [
              buildAppBar(context),
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadStudentData();
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24),
                          
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          Text(
                            studentName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Enhanced Attendance Card
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeeklyAttendancePage(),
                                  ),
                                ).then((_) => _loadStudentData()); // Refresh on return
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 50.0,
                                      lineWidth: 10.0,
                                      animation: true,
                                      percent: attendancePercentage.clamp(0.0, 1.0),
                                      center: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${(attendancePercentage * 100).toStringAsFixed(1)}%",
                                            style: GoogleFonts.raleway(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            ),
                                          ),
                                          Text(
                                            "$_presentPeriods/$_markedPeriods",
                                            style: GoogleFonts.raleway(
                                              fontSize: 12.0,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      circularStrokeCap: CircularStrokeCap.round,
                                      backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
                                      progressColor: Color(0xFF1B5E20),
                                    ),
                                    SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Your Attendance',
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1B5E20),
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: Color(0xFF1B5E20),
                                                size: 28,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Current Semester Status',
                                            style: GoogleFonts.raleway(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32),
                          
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          _buildMenuItem(
                            icon: Icons.calendar_month,
                            title: 'Timetable',
                            subtitle: 'View your class schedule',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TimetablePage()),
                              );
                            },
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.announcement_outlined,
                            title: 'Announcements',
                            subtitle: 'Check latest updates',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StudentAnnouncementsPage()),
                              );
                            },
                          ),

                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Profile',
                            subtitle: 'View and edit your details',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfilePage()),
                              );
                            },
                          ),

                          _buildMenuItem(
                            icon: Icons.support_agent,
                            title: 'Support',
                            subtitle: 'Get help and assistance',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SupportPage()),
                              );
                            },
                          ),
                          
                          SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1B5E20),
                    child: Text(
                      studentInitial,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    studentName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    'Student',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                // Navigate to settings
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupportPage()),
                );
              },
            ),
            Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF1B5E20)),
      title: Text(
        title,
        style: GoogleFonts.raleway(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Color(0xFF1B5E20)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Expanded(
            child: Text(
              'Dashboard',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF1B5E20)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
// import 'package:pro_1/screens/student/viewannouncement.dart';
// import 'package:pro_1/screens/student/student%20profile/student_profile.dart';
// import 'package:pro_1/screens/student/support.dart';
// import 'package:pro_1/screens/student/view_timetable.dart';
// import 'package:pro_1/screens/student/weekly_attendance.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pro_1/user_select.dart';
// import 'package:intl/intl.dart';

// class StudentHomePage extends StatefulWidget {
//   @override
//   _StudentHomePageState createState() => _StudentHomePageState();
// }

// class _StudentHomePageState extends State<StudentHomePage> {
//   String studentName = "Student";
//   String studentInitial = "S";
//   double attendancePercentage = 0.0;
//   bool isLoading = true;
  
//   // Student data
//   String _semester = '';
//   String _batch = '';
//   String _admissionNo = '';
  
//   // Semester details (adding from WeeklyAttendancePage)
//   DateTime? _semesterStartDate;
//   DateTime? _semesterEndDate;
//   List<String> _holidays = [];
//   String _semesterType = '';
  
//   // For timetable and attendance data (adding from WeeklyAttendancePage)
//   Map<String, Map<String, String>> _timetableData = {};
//   Map<String, Map<String, dynamic>> _attendanceData = {};
  
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
//     _loadStudentData();
//   }

//   Future<void> _loadStudentData() async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       final User? user = FirebaseAuth.instance.currentUser;
      
//       if (user != null) {
//         // Get user data from users collection
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         if (!userDoc.exists) {
//           setState(() {
//             isLoading = false;
//           });
//           return;
//         }

//         final userData = userDoc.data() as Map<String, dynamic>;
        
//         // Get the semester, batch and admission number from user data
//         final dynamic semesterRaw = userData['semester'];
//         final String semester = semesterRaw is int 
//             ? semesterRaw.toString() 
//             : (semesterRaw ?? '');
//         final String batch = userData['batch'] ?? '';
//         final String admissionNo = userData['admissionNo'] ?? '';
//         final String name = userData['name'] ?? 'Student';
        
//         setState(() {
//           studentName = name;
//           studentInitial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
//           _semester = semester;
//           _batch = batch;
//           _admissionNo = admissionNo;
//         });

//         print('User data loaded - Semester: $_semester, Batch: $_batch, AdmissionNo: $_admissionNo');

//         // Load semester details and attendance data
//         await _loadSemesterDetails();
//         await _loadTimetableData();
//         await _calculateAttendancePercentage();
//       } else {
//         // No user is signed in, redirect to login
//         setState(() {
//           isLoading = false;
//         });
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => UserSelectionPage()),
//           (route) => false,
//         );
//       }
//     } catch (e) {
//       print('Error loading student data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
  
//   // Load current semester details (from WeeklyAttendancePage)
//   Future<void> _loadSemesterDetails() async {
//     try {
//       // Get current semester details
//       final semesterDoc = await FirebaseFirestore.instance
//           .collection('attendance')
//           .doc('current_semester')
//           .get();
      
//       if (!semesterDoc.exists) {
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
//       });
      
//       print('Semester details loaded - Start: $_semesterStartDate, End: $_semesterEndDate');
//       print('Holidays: $_holidays');
      
//     } catch (e) {
//       print('Error loading semester details: $e');
//     }
//   }

//   // Load timetable data for the student's semester (from WeeklyAttendancePage)
//   Future<void> _loadTimetableData() async {
//     if (_semester.isEmpty) {
//       return;
//     }

//     try {
//       final timetableDoc = await FirebaseFirestore.instance
//           .collection('timetable')
//           .doc(_semester)
//           .get();
      
//       if (!timetableDoc.exists) {
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
//       });
      
//       print('Timetable loaded successfully');
      
//     } catch (e) {
//       print('Error loading timetable: $e');
//     }
//   }

//   // Calculate the attendance percentage based on the student's attendance data
//   Future<void> _calculateAttendancePercentage() async {
//     if (_semester.isEmpty || _batch.isEmpty || _admissionNo.isEmpty) {
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }

//     try {
//       print('Calculating attendance percentage for student: $_admissionNo');
      
//       // If the semester has start and end dates, use those for date range
//       DateTime startDate = _semesterStartDate ?? DateTime.now().subtract(Duration(days: 90));
//       DateTime endDate = _semesterEndDate ?? DateTime.now();
      
//       // List to store all the dates to check
//       List<DateTime> allDates = [];
      
//       // Generate all weekdays (Monday to Friday) in the date range
//       DateTime current = startDate;
//       while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
//         // Only add days from Monday (1) to Friday (5)
//         if (current.weekday >= 1 && current.weekday <= 5) {
//           allDates.add(current);
//         }
//         current = current.add(Duration(days: 1));
//       }
      
//       int totalPeriods = 0;
//       int presentPeriods = 0;
      
//       // For each date
//       for (DateTime date in allDates) {
//         String formattedDate = DateFormat('yyyy-MM-dd').format(date);
//         String dayName = DateFormat('EEEE').format(date);
        
//         // Skip holidays
//         if (_holidays.contains(formattedDate)) {
//           continue;
//         }
        
//         // For each period in the day
//         for (int periodIndex = 0; periodIndex < _timeSlots.length; periodIndex++) {
//           String timeSlot = _timeSlots[periodIndex];
//           String subject = _timetableData[dayName]?[timeSlot] ?? '';
          
//           // Skip if no subject scheduled
//           if (subject.isEmpty) {
//             continue;
//           }
          
//           // Format the document ID in the same way as WeeklyAttendancePage
//           String docId = '$timeSlot\_$subject';
          
//           try {
//             DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
//                 .collection('attendance')
//                 .doc('Sem$_semester')
//                 .collection(formattedDate)
//                 .doc(docId)
//                 .get();
                
//             if (attendanceDoc.exists) {
//               final data = attendanceDoc.data() as Map<String, dynamic>;
              
//               // Check if the document contains students data
//               if (data.containsKey('students') && data['students'] is List) {
//                 final List<dynamic> students = data['students'] as List<dynamic>;
                
//                 // Count this as a scheduled period regardless of attendance
//                 totalPeriods++;
                
//                 for (var student in students) {
//                   if (student is Map && 
//                       student.containsKey('studentId') && 
//                       student['studentId'] == _admissionNo) {
                    
//                     bool isPresent = student['isPresent'];
//                     if (isPresent) {
//                       presentPeriods++;
//                     }
//                     break;
//                   }
//                 }
//               }
//             }
//           } catch (e) {
//             print('Error checking attendance: $e');
//           }
//         }
//       }
      
//       // Calculate attendance percentage
//       double percentage = totalPeriods > 0 ? (presentPeriods / totalPeriods) : 0.0;
      
//       setState(() {
//         attendancePercentage = percentage;
//         isLoading = false;
//       });
      
//       print('Attendance calculation: $presentPeriods/$totalPeriods = ${(percentage * 100).toStringAsFixed(2)}%');
      
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print('Error calculating attendance: $e');
//     }
//   }

//   Future<void> _signOut() async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => UserSelectionPage()),
//         (route) => false,
//       );
//     } catch (e) {
//       print("Error signing out: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
    
//     if (isLoading) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//       );
//     }
    
//     return Scaffold(
//       drawer: _buildDrawer(context),
//       body: SafeArea(
//         child: Container(
//           height: screenSize.height,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 const Color.fromARGB(255, 223, 243, 225),
//                 Colors.white,
//               ],
//             ),
//           ),
//           child: Column(
//             children: [
//               buildAppBar(context),
              
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     await _loadStudentData();
//                   },
//                   child: SingleChildScrollView(
//                     physics: AlwaysScrollableScrollPhysics(),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 24),
                          
//                           Text(
//                             'Welcome back,',
//                             style: GoogleFonts.raleway(
//                               fontSize: 16,
//                               color: Colors.grey[600],
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           Text(
//                             studentName,
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           SizedBox(height: 24),
                          
//                           // Enhanced Attendance Card
//                           Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => WeeklyAttendancePage(),
//                                   ),
//                                 ).then((_) => _loadStudentData()); // Refresh on return
//                               },
//                               borderRadius: BorderRadius.circular(20),
//                               child: Container(
//                                 width: double.infinity,
//                                 padding: EdgeInsets.all(24),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.08),
//                                       blurRadius: 15,
//                                       offset: Offset(0, 5),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     CircularPercentIndicator(
//                                       radius: 50.0,
//                                       lineWidth: 10.0,
//                                       animation: true,
//                                       percent: attendancePercentage.clamp(0.0, 1.0),
//                                       center: Text(
//                                         "${(attendancePercentage * 100).toStringAsFixed(1)}%",
//                                         style: GoogleFonts.raleway(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 20.0,
//                                         ),
//                                       ),
//                                       circularStrokeCap: CircularStrokeCap.round,
//                                       backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
//                                       progressColor: Color(0xFF1B5E20),
//                                     ),
//                                     SizedBox(width: 24),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Expanded(
//                                                 child: Text(
//                                                   'Your Attendance',
//                                                   style: GoogleFonts.playfairDisplay(
//                                                     fontSize: 22,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: Color(0xFF1B5E20),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Icon(
//                                                 Icons.chevron_right,
//                                                 color: Color(0xFF1B5E20),
//                                                 size: 28,
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(height: 8),
//                                           Text(
//                                             'Current Semester Status',
//                                             style: GoogleFonts.raleway(
//                                               fontSize: 16,
//                                               color: Colors.grey[600],
//                                               letterSpacing: 0.5,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
                          
//                           SizedBox(height: 32),
                          
//                           Text(
//                             'Quick Actions',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           SizedBox(height: 20),
                          
//                           _buildMenuItem(
//                             icon: Icons.calendar_month,
//                             title: 'Timetable',
//                             subtitle: 'View your class schedule',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => TimetablePage()),
//                               );
//                             },
//                           ),
                          
//                           _buildMenuItem(
//                             icon: Icons.announcement_outlined,
//                             title: 'Announcements',
//                             subtitle: 'Check latest updates',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => AnnouncementsPage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.person_outline,
//                             title: 'Profile',
//                             subtitle: 'View and edit your details',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => ProfilePage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.support_agent,
//                             title: 'Support',
//                             subtitle: 'Get help and assistance',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => SupportPage()),
//                               );
//                             },
//                           ),
                          
//                           SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     const Color.fromARGB(255, 223, 243, 225),
//                     Colors.white,
//                   ],
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Color(0xFF1B5E20),
//                     child: Text(
//                       studentInitial,
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: 24,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     studentName,
//                     style: GoogleFonts.playfairDisplay(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                   Text(
//                     'Student',
//                     style: GoogleFonts.raleway(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               icon: Icons.person_outline,
//               title: 'Profile',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfilePage()),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.settings_outlined,
//               title: 'Settings',
//               onTap: () {
//                 // Navigate to settings
//                 Navigator.pop(context);
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SupportPage()),
//                 );
//               },
//             ),
//             Divider(),
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () {
//                 Navigator.pop(context);
//                 _signOut();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Color(0xFF1B5E20)),
//       title: Text(
//         title,
//         style: GoogleFonts.raleway(
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget buildAppBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           Builder(
//             builder: (context) => IconButton(
//               icon: Icon(Icons.menu, color: Color(0xFF1B5E20)),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ),
//           Expanded(
//             child: Text(
//               'Dashboard',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications_none, color: Color(0xFF1B5E20)),
//             onPressed: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Color(0xFF1B5E20).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Color(0xFF1B5E20),
//                     size: 20,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: GoogleFonts.raleway(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         subtitle,
//                         style: GoogleFonts.raleway(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.chevron_right,
//                   color: Colors.grey[400],
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

















//-----------------------------------------------------------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
// import 'package:pro_1/screens/student/viewannouncement.dart';
// import 'package:pro_1/screens/student/student%20profile/student_profile.dart';
// import 'package:pro_1/screens/student/support.dart';
// import 'package:pro_1/screens/student/view_timetable.dart';
// import 'package:pro_1/screens/student/weekly_attendance.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pro_1/user_select.dart';

// class StudentHomePage extends StatefulWidget {
//   @override
//   _StudentHomePageState createState() => _StudentHomePageState();
// }

// class _StudentHomePageState extends State<StudentHomePage> {
//   String studentName = "Student";
//   String studentInitial = "S";
//   double attendancePercentage = 0.0;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadStudentData();
//   }

//   Future<void> _loadStudentData() async {
//     try {
//       final User? user = FirebaseAuth.instance.currentUser;
      
//       if (user != null) {
//         // Get student data from Firestore
//         final QuerySnapshot studentQuery = await FirebaseFirestore.instance
//             .collection('students')
//             .where('email', isEqualTo: user.email)
//             .get();
        
//         if (studentQuery.docs.isNotEmpty) {
//           final studentData = studentQuery.docs.first.data() as Map<String, dynamic>;
          
//           // Get attendance data
//           final attendanceSnapshot = await FirebaseFirestore.instance
//               .collection('attendance')
//               .where('studentId', isEqualTo: studentData['studentId'])
//               .get();
          
//           // Calculate attendance percentage
//           int totalClasses = 0;
//           int attendedClasses = 0;
          
//           attendanceSnapshot.docs.forEach((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             totalClasses++;
//             if (data['status'] == 'present') {
//               attendedClasses++;
//             }
//           });
          
//           double percentage = totalClasses > 0 
//               ? (attendedClasses / totalClasses) * 100 
//               : 0.0;
          
//           setState(() {
//             studentName = studentData['name'] ?? 'Student';
//             studentInitial = studentName.isNotEmpty ? studentName[0] : 'S';
//             attendancePercentage = percentage / 100; // Divide by 100 for CircularPercentIndicator
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             isLoading = false;
//           });
//         }
//       } else {
//         // No user is signed in, redirect to login
//         setState(() {
//           isLoading = false;
//         });
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => UserSelectionPage()),
//           (route) => false,
//         );
//       }
//     } catch (e) {
//       print('Error loading student data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _signOut() async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => UserSelectionPage()),
//         (route) => false,
//       );
//     } catch (e) {
//       print("Error signing out: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
    
//     if (isLoading) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//       );
//     }
    
//     return Scaffold(
//       drawer: _buildDrawer(context),
//       body: SafeArea(
//         child: Container(
//           height: screenSize.height,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 const Color.fromARGB(255, 223, 243, 225),
//                 Colors.white,
//               ],
//             ),
//           ),
//           child: Column(
//             children: [
//               buildAppBar(context),
              
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     await _loadStudentData();
//                   },
//                   child: SingleChildScrollView(
//                     physics: AlwaysScrollableScrollPhysics(),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 24),
                          
//                           Text(
//                             'Welcome back,',
//                             style: GoogleFonts.raleway(
//                               fontSize: 16,
//                               color: Colors.grey[600],
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           Text(
//                             studentName,
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           SizedBox(height: 24),
                          
//                           // Enhanced Attendance Card
//                           Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => WeeklyAttendancePage(),
//                                   ),
//                                 );
//                               },
//                               borderRadius: BorderRadius.circular(20),
//                               child: Container(
//                                 width: double.infinity,
//                                 padding: EdgeInsets.all(24),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.08),
//                                       blurRadius: 15,
//                                       offset: Offset(0, 5),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     CircularPercentIndicator(
//                                       radius: 50.0,
//                                       lineWidth: 10.0,
//                                       animation: true,
//                                       percent: attendancePercentage,
//                                       center: Text(
//                                         "${(attendancePercentage * 100).toStringAsFixed(0)}%",
//                                         style: GoogleFonts.raleway(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 20.0,
//                                         ),
//                                       ),
//                                       circularStrokeCap: CircularStrokeCap.round,
//                                       backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
//                                       progressColor: Color(0xFF1B5E20),
//                                     ),
//                                     SizedBox(width: 24),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Expanded(
//                                                 child: Text(
//                                                   'Your Attendance',
//                                                   style: GoogleFonts.playfairDisplay(
//                                                     fontSize: 22,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: Color(0xFF1B5E20),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Icon(
//                                                 Icons.chevron_right,
//                                                 color: Color(0xFF1B5E20),
//                                                 size: 28,
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(height: 8),
//                                           Text(
//                                             'Current Semester Status',
//                                             style: GoogleFonts.raleway(
//                                               fontSize: 16,
//                                               color: Colors.grey[600],
//                                               letterSpacing: 0.5,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
                          
//                           SizedBox(height: 32),
                          
//                           Text(
//                             'Quick Actions',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           SizedBox(height: 20),
                          
//                           _buildMenuItem(
//                             icon: Icons.calendar_month,
//                             title: 'Timetable',
//                             subtitle: 'View your class schedule',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => TimetablePage()),
//                               );
//                             },
//                           ),
                          
//                           _buildMenuItem(
//                             icon: Icons.announcement_outlined,
//                             title: 'Announcements',
//                             subtitle: 'Check latest updates',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => AnnouncementsPage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.person_outline,
//                             title: 'Profile',
//                             subtitle: 'View and edit your details',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => ProfilePage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.support_agent,
//                             title: 'Support',
//                             subtitle: 'Get help and assistance',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => SupportPage()),
//                               );
//                             },
//                           ),
                          
//                           SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     const Color.fromARGB(255, 223, 243, 225),
//                     Colors.white,
//                   ],
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Color(0xFF1B5E20),
//                     child: Text(
//                       studentInitial,
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: 24,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     studentName,
//                     style: GoogleFonts.playfairDisplay(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                   Text(
//                     'Student',
//                     style: GoogleFonts.raleway(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               icon: Icons.person_outline,
//               title: 'Profile',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfilePage()),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.settings_outlined,
//               title: 'Settings',
//               onTap: () {
//                 // Navigate to settings
//                 Navigator.pop(context);
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SupportPage()),
//                 );
//               },
//             ),
//             Divider(),
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () {
//                 Navigator.pop(context);
//                 _signOut();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Color(0xFF1B5E20)),
//       title: Text(
//         title,
//         style: GoogleFonts.raleway(
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget buildAppBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           Builder(
//             builder: (context) => IconButton(
//               icon: Icon(Icons.menu, color: Color(0xFF1B5E20)),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ),
//           Expanded(
//             child: Text(
//               'Dashboard',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications_none, color: Color(0xFF1B5E20)),
//             onPressed: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Color(0xFF1B5E20).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Color(0xFF1B5E20),
//                     size: 20,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: GoogleFonts.raleway(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         subtitle,
//                         style: GoogleFonts.raleway(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.chevron_right,
//                   color: Colors.grey[400],
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }








// ------------------------------------------------------------------------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
// import 'package:pro_1/screens/student/viewannouncement.dart';
// import 'package:pro_1/screens/student/student_profile.dart';
// import 'package:pro_1/screens/student/support.dart';
// import 'package:pro_1/screens/student/view_timetable.dart';
// import 'package:pro_1/screens/student/weekly_attendance.dart';

// class StudentHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
    
//     return Scaffold(
//       drawer: _buildDrawer(context),
//       body: SafeArea(
//         child: Container(
//           height: screenSize.height,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 const Color.fromARGB(255, 223, 243, 225),
//                 Colors.white,
//               ],
//             ),
//           ),
//           child: Column(
//             children: [
//               buildAppBar(context),
              
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     // Add refresh logic here
//                   },
//                   child: SingleChildScrollView(
//                     physics: AlwaysScrollableScrollPhysics(),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 24),
                          
//                           Text(
//                             'Welcome back,',
//                             style: GoogleFonts.raleway(
//                               fontSize: 16,
//                               color: Colors.grey[600],
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           Text(
//                             'Fuhad',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
                          
//                           SizedBox(height: 24),
                          
//                           // Enhanced Attendance Card
//                           Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => WeeklyAttendancePage(),
//                                   ),
//                                 );
//                               },
//                               borderRadius: BorderRadius.circular(20),
//                               child: Container(
//                                 width: double.infinity,
//                                 padding: EdgeInsets.all(24),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.08),
//                                       blurRadius: 15,
//                                       offset: Offset(0, 5),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     CircularPercentIndicator(
//                                       radius: 50.0,
//                                       lineWidth: 10.0,
//                                       animation: true,
//                                       percent: 0.85,
//                                       center: Text(
//                                         "85%",
//                                         style: GoogleFonts.raleway(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 20.0,
//                                         ),
//                                       ),
//                                       circularStrokeCap: CircularStrokeCap.round,
//                                       backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
//                                       progressColor: Color(0xFF1B5E20),
//                                     ),
//                                     SizedBox(width: 24),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Expanded(
//                                                 child: Text(
//                                                   'Your Attendance',
//                                                   style: GoogleFonts.playfairDisplay(
//                                                     fontSize: 22,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: Color(0xFF1B5E20),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Icon(
//                                                 Icons.chevron_right,
//                                                 color: Color(0xFF1B5E20),
//                                                 size: 28,
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(height: 8),
//                                           Text(
//                                             'Current Semester Status',
//                                             style: GoogleFonts.raleway(
//                                               fontSize: 16,
//                                               color: Colors.grey[600],
//                                               letterSpacing: 0.5,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
                          
//                           SizedBox(height: 32),
                          
//                           Text(
//                             'Quick Actions',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           SizedBox(height: 20),
                          
//                           _buildMenuItem(
//                             icon: Icons.calendar_month,
//                             title: 'Timetable',
//                             subtitle: 'View your class schedule',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => TimetablePage()),
//                               );
//                             },
//                           ),
                          
//                           _buildMenuItem(
//                             icon: Icons.announcement_outlined,
//                             title: 'Announcements',
//                             subtitle: 'Check latest updates',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => AnnouncementsPage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.person_outline,
//                             title: 'Profile',
//                             subtitle: 'View and edit your details',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => ProfilePage()),
//                               );
//                             },
//                           ),

//                           _buildMenuItem(
//                             icon: Icons.support_agent,
//                             title: 'Support',
//                             subtitle: 'Get help and assistance',
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => SupportPage()),
//                               );
//                             },
//                           ),
                          
//                           SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // [Previous methods remain unchanged - _buildDrawer, _buildDrawerItem, buildAppBar, and _buildMenuItem stay the same]
//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     const Color.fromARGB(255, 223, 243, 225),
//                     Colors.white,
//                   ],
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Color(0xFF1B5E20),
//                     child: Text(
//                       'F',
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: 24,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Fuhad',
//                     style: GoogleFonts.playfairDisplay(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                   Text(
//                     'Student',
//                     style: GoogleFonts.raleway(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               icon: Icons.person_outline,
//               title: 'Profile',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfilePage()),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.settings_outlined,
//               title: 'Settings',
//               onTap: () {
//                 // Navigate to settings
//                 Navigator.pop(context);
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SupportPage()),
//                 );
//               },
//             ),
//             Divider(),
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () {
//                 // Implement logout logic
//                 Navigator.pop(context);
//                 // Add your logout navigation here
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Color(0xFF1B5E20)),
//       title: Text(
//         title,
//         style: GoogleFonts.raleway(
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget buildAppBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           Builder(
//             builder: (context) => IconButton(
//               icon: Icon(Icons.menu, color: Color(0xFF1B5E20)),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ),
//           Expanded(
//             child: Text(
//               'Dashboard',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications_none, color: Color(0xFF1B5E20)),
//             onPressed: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickAccessButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Color(0xFF1B5E20), size: 24),
//             SizedBox(height: 8),
//             Text(
//               label,
//               style: GoogleFonts.raleway(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Color(0xFF1B5E20).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Color(0xFF1B5E20),
//                     size: 20,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: GoogleFonts.raleway(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         subtitle,
//                         style: GoogleFonts.raleway(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.chevron_right,
//                   color: Colors.grey[400],
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }