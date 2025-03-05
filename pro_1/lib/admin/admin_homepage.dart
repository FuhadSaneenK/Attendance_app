import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/admin/admin-profile.dart';
import 'package:pro_1/admin/student_part/admin_student_manage.dart';
import 'package:pro_1/admin/announcement.dart';
import 'package:pro_1/admin/teacher_part/admin_teacher_manage.dart';

class AdminHomePage extends StatelessWidget {
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
                    // Add refresh logic here
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
                            'Admin',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
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
                          
                          // User Management - Now shows a dialog with options
                          _buildMenuItem(
                            icon: Icons.people_alt_outlined,
                            title: 'User Management',
                            subtitle: 'Manage students & teachers',
                            onTap: () {
                              _showUserManagementOptions(context);
                            },
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.announcement_outlined,
                            title: 'Announcements',
                            subtitle: 'Post school-wide updates',
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => AnnouncementsPage(),
                                ),
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
                                MaterialPageRoute(
                                  builder: (context) => AdminProfilePage(),
                                ),
                              );
                            },
                          ),

                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'Configure system settings',
                            onTap: () {
                              // Navigate to Settings page
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

  // New method for showing user management options dialog
  void _showUserManagementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.people_alt, color: Color(0xFF1B5E20), size: 28),
                  SizedBox(width: 16),
                  Text(
                    'User Management',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.school,
                color: Color(0xFF1B5E20),
                size: 28,
              ),
              title: Text(
                'Student Management',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                'Add, edit, or remove student accounts',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Student Management page
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => StudentManagementPage(),
                  ),
                );
              },
            ),
            Divider(indent: 70, endIndent: 24),
            ListTile(
              leading: Icon(
                Icons.person_pin,
                color: Color(0xFF1B5E20),
                size: 28,
              ),
              title: Text(
                'Teacher Management',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                'Add, edit, or remove teacher accounts',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Teacher Management page
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => TeacherManagementPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
          ],
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
                    radius: 35,
                    backgroundColor: Color(0xFF1B5E20),
                    child: Text(
                      'A',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Admin Portal',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    'System Administrator',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // User Management with submenu in drawer
            ExpansionTile(
              leading: Icon(Icons.people_alt_outlined, color: Color(0xFF1B5E20), size: 24),
              title: Text(
                'User Management',
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 56),
                  title: Text(
                    'Student Management',
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  leading: Icon(Icons.school, color: Color(0xFF1B5E20), size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Student Management page
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => StudentManagementPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 56),
                  title: Text(
                    'Teacher Management',
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  leading: Icon(Icons.person_pin, color: Color(0xFF1B5E20), size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Teacher Management page
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => TeacherManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildDrawerItem(
              icon: Icons.announcement_outlined,
              title: 'Announcements',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AdminProfilePage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to Settings page
              },
            ),
            Divider(thickness: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                // Add logout logic here
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
              'Admin Dashboard',
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
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF1B5E20),
                    size: 24,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
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
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}