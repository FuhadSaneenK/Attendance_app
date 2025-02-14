import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_login.dart';
import 'teacher_login.dart';
import 'admin_login.dart';

class UserSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/agriculture_logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'College of Agriculture',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Select your role to continue',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48),

                    // Main Role Selection Cards
                    _buildMainRoleCard(
                      context,
                      'Student',
                      Icons.school_outlined,
                      'Access your courses, assignments, and academic resources',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentLoginPage()),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildMainRoleCard(
                      context,
                      'Teacher',
                      Icons.person_outline,
                      'Manage your classes, grades, and teaching materials',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TeacherLoginPage()),
                      ),
                    ),

                    // Footer Section with Admin Option
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0),
                      child: Column(
                        children: [
                          Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                          SizedBox(height: 16),
                          _buildAdminButton(context),
                          SizedBox(height: 24),
                          Text(
                            '© 2025 College of Agriculture',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainRoleCard(
    BuildContext context,
    String role,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1B5E20),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    return TextButton.icon(
      // In _buildAdminButton
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
        );
      },
      icon: Icon(
        Icons.admin_panel_settings_outlined,
        size: 20,
        color: Color(0xFF1B5E20),
      ),
      label: Text(
        'Administrator Login',
        style: GoogleFonts.raleway(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}