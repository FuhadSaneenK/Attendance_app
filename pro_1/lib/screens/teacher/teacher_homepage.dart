import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/screens/admin/teacher_part/add_subjects.dart';
import 'package:pro_1/screens/student/viewannouncement.dart';
import 'package:pro_1/screens/teacher/add%20attendance/add_attendance.dart';
import 'package:pro_1/screens/teacher/add_subject.dart';
import 'package:pro_1/screens/teacher/add_timetable.dart';
import 'package:pro_1/screens/teacher/teacher_profile/teacher_profile.dart';
import 'package:pro_1/screens/teacher/teacher_support.dart';// Import the new page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/screens/teacher/update_result.dart';
import 'package:pro_1/user_select.dart';
import 'package:pro_1/screens/admin/student_part/view_students/viewstudent.dart';

class TeacherHomePage extends StatefulWidget {
  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _teacherName = 'Teacher';
  String _position = 'Faculty';
  String _initial = 'T';
  String _teacherId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // First try to get user data from the users collection
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String teacherId = userData['teacherId'] ?? '';
          
          if (teacherId.isNotEmpty) {
            // Try to get teacher data using teacherId
            DocumentSnapshot teacherDoc = await _firestore
                .collection('teachers')
                .doc(teacherId)
                .get();
                
            if (teacherDoc.exists) {
              Map<String, dynamic> teacherData = teacherDoc.data() as Map<String, dynamic>;
              
              setState(() {
                _teacherId = teacherId;
                _teacherName = teacherData['name'] ?? userData['name'] ?? 'Teacher';
                _position = teacherData['position'] ?? 'Faculty';
                // Get first letter of name for avatar
                _initial = _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T';
                _isLoading = false;
              });
              return;
            } else {
              // If teacher doc not found by teacherId, use user data
              setState(() {
                _teacherId = teacherId;
                _teacherName = userData['name'] ?? 'Teacher';
                _position = userData['role'] ?? 'Faculty';
                _initial = _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T';
                _isLoading = false;
              });
              return;
            }
          } else {
            // No teacherId found, just use the user data
            setState(() {
              _teacherId = currentUser.uid;
              _teacherName = userData['name'] ?? 'Teacher';
              _position = userData['role'] ?? 'Faculty';
              _initial = _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T';
              _isLoading = false;
            });
            return;
          }
        }
        
        // If no user document, try getting teacher data directly from teachers collection
        DocumentSnapshot teacherDoc = await _firestore
            .collection('teachers')
            .doc(currentUser.uid)
            .get();
            
        if (teacherDoc.exists) {
          Map<String, dynamic> teacherData = teacherDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _teacherId = currentUser.uid;
            _teacherName = teacherData['name'] ?? 'Teacher';
            _position = teacherData['position'] ?? 'Faculty';
            // Get first letter of name for avatar
            _initial = _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T';
            _isLoading = false;
          });
          return;
        }
        
        // If we get here, we couldn't find the teacher data
        setState(() {
          _teacherId = currentUser.uid;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading teacher data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Implement logout functionality
  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      // Navigate to login page - You need to replace '/login' with your actual login route
      Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => UserSelectionPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
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
                    await _loadTeacherData();
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16), // Reduced from 24 to 16
                          
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          _isLoading
                          ? _buildLoadingName()
                          : Text(
                              _teacherName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26, // Reduced from 28 to 26
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                                letterSpacing: 0.5,
                              ),
                            ),
                          
                          SizedBox(height: 16), // Reduced from 24 to 16
                          
                          // Redesigned Attendance Card - with adjusted padding
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MarkAttendancePage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20), // Reduced from 24 to 20
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
                                    Container(
                                      padding: EdgeInsets.all(14), // Reduced from 16 to 14
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1B5E20).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.edit_calendar_rounded,
                                        color: Color(0xFF1B5E20),
                                        size: 30, // Reduced from 32 to 30
                                      ),
                                    ),
                                    SizedBox(width: 20), // Reduced from 24 to 20
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Mark Attendance',
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 20, // Reduced from 22 to 20
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1B5E20),
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: Color(0xFF1B5E20),
                                                size: 26, // Reduced from 28 to 26
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6), // Reduced from 8 to 6
                                          Text(
                                            'Record today\'s class attendance',
                                            style: GoogleFonts.raleway(
                                              fontSize: 15, // Reduced from 16 to 15
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
                          
                          SizedBox(height: 24), // Reduced from 32 to 24
                          
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22, // Reduced from 24 to 22
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 16), // Reduced from 20 to 16
                          
                          // New menu item for managing teaching subjects
                          _buildMenuItem(
                            icon: Icons.book,
                            title: 'My Subjects',
                            subtitle: 'Manage subjects you teach',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageTeachingSubjectsPage(
                                    teacherId: _teacherId,
                                  ),
                                ),
                              );
                            },
                          ),

                          _buildMenuItem(
                            icon: Icons.calendar_month,
                            title: 'Timetable',
                            subtitle: 'Manage class schedule',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ManageTimetablePage()),
                              );
                            },
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.announcement_outlined,
                            title: 'Announcements',
                            subtitle: 'Post new updates',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StudentAnnouncementsPage()),
                              );
                            },
                          ),

//------
                            _buildMenuItem(
                            icon: Icons.announcement_outlined,
                            title: 'Update Results',
                            subtitle: 'Mark student pass/fail status',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UpdateResultsPage()),
                              );
                            },
                          ),

//-------
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Profile',
                            subtitle: 'View and edit your details',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TeacherProfile()),
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
                                MaterialPageRoute(builder: (context) => TeacherSupport()),
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

  Widget _buildLoadingName() {
    return Container(
      width: 150,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom padding
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
              mainAxisSize: MainAxisSize.min, // Minimize vertical space
              children: [
                CircleAvatar(
                  radius: 32, // Reduced from 35
                  backgroundColor: Color(0xFF1B5E20),
                  child: Text(
                    _initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26, // Reduced from 28
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8), // Reduced from 12
                Text(
                  _teacherName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22, // Reduced from 24
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  _position,
                  style: GoogleFonts.raleway(
                    fontSize: 14, // Reduced from 16
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
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
                MaterialPageRoute(builder: (context) => TeacherProfile()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.book,
            title: 'My Subjects',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageTeachingSubjectsPage(
                    teacherId: _teacherId,
                  ),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
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
                MaterialPageRoute(builder: (context) => TeacherSupport()),
              );
            },
          ),
          Divider(thickness: 1),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              // Perform the logout operation
              _auth.signOut().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserSelectionPage()),
                  (route) => false,
                );
              });
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
      leading: Icon(icon, color: Color(0xFF1B5E20), size: 24),
      title: Text(
        title,
        style: GoogleFonts.raleway(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Color(0xFF1B5E20), size: 28),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Expanded(
            child: Text(
              'Dashboard',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF1B5E20), size: 28),
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
      margin: EdgeInsets.only(bottom: 14), // Reduced from 16 to 14
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16), // Reduced from 20 to 16
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10), // Reduced from 12 to 10
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF1B5E20),
                    size: 22, // Reduced from 24 to 22
                  ),
                ),
                SizedBox(width: 16), // Reduced from 20 to 16
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.raleway(
                          fontSize: 17, // Reduced from 18 to 17
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 3), // Reduced from 4 to 3
                      Text(
                        subtitle,
                        style: GoogleFonts.raleway(
                          fontSize: 13, // Reduced from 14 to 13
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 22, // Reduced from 24 to 22
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


