import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/user_select.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Student data map
  Map<String, dynamic> studentData = {
    'name': '',
    'mobile': '',
    'email': '',
    'admissionNo': '',
    'department': '',
    'semester': '',
    'batch': '',
  };

  bool _isLoading = true;
  String _errorMessage = '';

  // Text controllers for edit profile
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    nameController = TextEditingController();
    mobileController = TextEditingController();
    emailController = TextEditingController();
    
    // Fetch user data when the widget is initialized
    _fetchUserData();
  }

  @override
  void dispose() {
    // Clean up controllers
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Fetch user data from Firebase
  Future<void> _fetchUserData() async {
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
      final String semester = semesterRaw is int ? semesterRaw.toString() : (semesterRaw ?? '');
      final String batch = userData['batch'] ?? '';
      final String admissionNo = userData['admissionNo'] ?? '';
      
      // Now fetch the detailed student data from classes collection
      final studentDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc('Sem$semester')
          .collection('Batch${batch.toLowerCase()}')
          .doc(admissionNo)
          .get();

      if (!studentDoc.exists) {
        // If student doc doesn't exist, use the basic user data
        setState(() {
          studentData = {
            'name': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'admissionNo': admissionNo,
            'department': 'MCA', // Default or fetch from elsewhere
            'semester': semester,
            'batch': batch,
            'mobile': '', // Default empty
          };
          _isLoading = false;
        });
      } else {
        // Combine data from both collections
        final classData = studentDoc.data() as Map<String, dynamic>;
        
        setState(() {
          studentData = {
            'name': classData['name'] ?? userData['name'] ?? '',
            'email': classData['email'] ?? userData['email'] ?? '',
            'admissionNo': admissionNo,
            'department': 'MCA', // Default or fetch from elsewhere
            'semester': semester,
            'batch': batch,
            'mobile': classData['mobile'] ?? '', // This might be stored elsewhere
          };
          _isLoading = false;
        });
      }

      // Update controllers with current values
      nameController.text = studentData['name'] ?? '';
      mobileController.text = studentData['mobile'] ?? '';
      emailController.text = studentData['email'] ?? '';
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching profile: ${e.toString()}';
      });
      print('Error fetching user data: $e');
    }
  }

  // Update profile data in Firebase
  Future<void> _updateProfile() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String semester = studentData['semester'] ?? '';
      final String batch = studentData['batch'] ?? '';
      final String admissionNo = studentData['admissionNo'] ?? '';
      
      // Update in users collection
      // Update in users collection
        await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
          'name': nameController.text,
          'email': emailController.text,
          // Convert string to int if needed
          // 'semester': int.parse(studentData['semester']),
        });
      
      // Update in classes collection
      await FirebaseFirestore.instance
          .collection('classes')
          .doc('Sem$semester')
          .collection('Batch${batch.toLowerCase()}')
          .doc(admissionNo)
          .update({
            'name': nameController.text,
            'email': emailController.text,
            'mobile': mobileController.text,
          });

      // Update local state
      setState(() {
        studentData['name'] = nameController.text;
        studentData['email'] = emailController.text;
        studentData['mobile'] = mobileController.text;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
          child: Column(
            children: [
              _buildAppBar(),
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchUserData,
                    color: Color(0xFF1B5E20),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildProfileDetails(),
                          _buildActionButtons(),
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

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'My Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Color(0xFF1B5E20)),
            onPressed: _isLoading ? null : () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Add photo update functionality
                    },
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            studentData['name'] ?? '',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          Text(
            studentData['department'] ?? '',
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailItem('Name', studentData['name'] ?? '', Icons.person),
          _buildDivider(),
          _buildDetailItem('Mobile Number', studentData['mobile'] ?? '', Icons.phone),
          _buildDivider(),
          _buildDetailItem('Email', studentData['email'] ?? '', Icons.email),
          _buildDivider(),
          _buildDetailItem('Admission No.', studentData['admissionNo'] ?? '', Icons.badge),
          _buildDivider(),
          _buildDetailItem('Semester', studentData['semester'] ?? '', Icons.school),
          _buildDivider(),
          _buildDetailItem('Batch', studentData['batch'] ?? '', Icons.date_range),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
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
              size: 20,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[200],
      thickness: 1,
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton(
            'Update Password',
            Icons.lock_outline,
            onTap: () {
              _showUpdatePasswordDialog();
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            'Edit Profile',
            Icons.edit_outlined,
            onTap: () {
              _showEditProfileDialog();
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            'Logout',
            Icons.logout,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // Use this if you have access to a GlobalKey<NavigatorState>
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => UserSelectionPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF1B5E20)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Color(0xFF1B5E20),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdatePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Update Password',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                // Get current user
                final User? user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                
                // Reauthenticate user
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPasswordController.text,
                );
                
                await user.reauthenticateWithCredential(credential);
                
                // Change password
                await user.updatePassword(newPasswordController.text);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password updated successfully'),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating password: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    // Reset controllers to current values
    nameController.text = studentData['name'] ?? '';
    mobileController.text = studentData['mobile'] ?? '';
    emailController.text = studentData['email'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: mobileController,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: 16),
            // Read-only fields
            TextField(
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Admission No.',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: studentData['admissionNo'] ?? '',
                hintStyle: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}























// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProfilePage extends StatefulWidget {
//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   // Sample student data - replace with actual data
//   final Map<String, String> studentData = {
//     'name': 'Fuhad Saneen K',
//     'mobile': '+91 7034728445',
//     'email': '2343@tkmce.ac.in',
//     'admissionNumber': '2343',
//     'department': 'MCA',
//     'semester': '4th Semester',
//     'batch': '2023-2025',
//   };

//   // Text controllers for edit profile
//   late TextEditingController nameController;
//   late TextEditingController mobileController;
//   late TextEditingController emailController;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with current values
//     nameController = TextEditingController(text: studentData['name']);
//     mobileController = TextEditingController(text: studentData['mobile']);
//     emailController = TextEditingController(text: studentData['email']);
//   }

//   @override
//   void dispose() {
//     // Clean up controllers
//     nameController.dispose();
//     mobileController.dispose();
//     emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
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
//               _buildAppBar(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildProfileHeader(),
//                       _buildProfileDetails(),
//                       _buildActionButtons(),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//             onPressed: () => Navigator.pop(context),
//           ),
//           Expanded(
//             child: Text(
//               'My Profile',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.edit, color: Color(0xFF1B5E20)),
//             onPressed: () {
//               _showEditProfileDialog();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     return Container(
//       padding: EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.white,
//                     width: 4,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: CircleAvatar(
//                   backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
//                   child: Icon(
//                     Icons.person,
//                     size: 60,
//                     color: Color(0xFF1B5E20),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 0,
//                 bottom: 0,
//                 child: Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Color(0xFF1B5E20),
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       // Add photo update functionality
//                     },
//                     child: Icon(
//                       Icons.camera_alt,
//                       size: 20,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           Text(
//             studentData['name']!,
//             style: GoogleFonts.playfairDisplay(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           Text(
//             studentData['department']!,
//             style: GoogleFonts.raleway(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileDetails() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16),
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           _buildDetailItem('Name',  studentData['name']!, Icons.person),
//           _buildDivider(),
//           _buildDetailItem('Mobile Number', studentData['mobile']!, Icons.phone),
//           _buildDivider(),
//           _buildDetailItem('Email', studentData['email']!, Icons.email),
//           _buildDivider(),
//           _buildDetailItem('Admission No.', studentData['admissionNumber']!, Icons.badge),
//           _buildDivider(),
//           _buildDetailItem('Semester', studentData['semester']!, Icons.school),
//           _buildDivider(),
//           _buildDetailItem('Batch', studentData['batch']!, Icons.date_range),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailItem(String label, String value, IconData icon) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Color(0xFF1B5E20).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 20,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: GoogleFonts.raleway(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: GoogleFonts.raleway(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Divider(
//       color: Colors.grey[200],
//       thickness: 1,
//     );
//   }

//   Widget _buildActionButtons() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           _buildActionButton(
//             'Update Password',
//             Icons.lock_outline,
//             onTap: () {
//               _showUpdatePasswordDialog();
//             },
//           ),
//           SizedBox(height: 12),
//           _buildActionButton(
//             'Edit Profile',
//             Icons.edit_outlined,
//             onTap: () {
//               _showEditProfileDialog();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(String label, IconData icon, {required VoidCallback onTap}) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//           decoration: BoxDecoration(
//             border: Border.all(color: Color(0xFF1B5E20)),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 20,
//                 color: Color(0xFF1B5E20),
//               ),
//               SizedBox(width: 12),
//               Text(
//                 label,
//                 style: GoogleFonts.raleway(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1B5E20),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showUpdatePasswordDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(
//           'Update Password',
//           style: GoogleFonts.playfairDisplay(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: 'Current Password',
//                 prefixIcon: Icon(Icons.lock_outline),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: 'New Password',
//                 prefixIcon: Icon(Icons.lock_outline),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: 'Confirm New Password',
//                 prefixIcon: Icon(Icons.lock_outline),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(
//                 color: Color(0xFF1B5E20),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Add password update logic
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF1B5E20),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Update',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // New method for Edit Profile dialog
//   void _showEditProfileDialog() {
//     // Reset controllers to current values
//     nameController.text = studentData['name']!;
//     mobileController.text = studentData['mobile']!;
//     emailController.text = studentData['email']!;
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(
//           'Edit Profile',
//           style: GoogleFonts.playfairDisplay(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(
//                 labelText: 'Name',
//                 prefixIcon: Icon(Icons.person_outline),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: mobileController,
//               decoration: InputDecoration(
//                 labelText: 'Mobile Number',
//                 prefixIcon: Icon(Icons.phone_outlined),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: emailController,
//               decoration: InputDecoration(
//                 labelText: 'Email',
//                 prefixIcon: Icon(Icons.email_outlined),
//               ),
//             ),
//             SizedBox(height: 16),
//             // Read-only fields
//             TextField(
//               readOnly: true,
//               enabled: false,
//               decoration: InputDecoration(
//                 labelText: 'Admission No.',
//                 prefixIcon: Icon(Icons.badge_outlined),
//                 hintText: studentData['admissionNumber'],
//                 hintStyle: TextStyle(color: Colors.grey[700]),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: TextStyle(
//                 color: Color(0xFF1B5E20),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Update the profile data
//               setState(() {
//                 studentData['name'] = nameController.text;
//                 studentData['mobile'] = mobileController.text;
//                 studentData['email'] = emailController.text;
//               });
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF1B5E20),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Save',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }