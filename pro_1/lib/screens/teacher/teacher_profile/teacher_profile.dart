import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TeacherProfile extends StatefulWidget {
  @override
  _TeacherProfileState createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  bool isEditing = false;
  bool isLoading = true;
  String errorMessage = '';
  bool isProfileFound = false;
  
  // Map to store teacher data
  Map<String, dynamic> teacherData = {
    'name': '',
    'email': '',
    'phone': '',
    'employeeId': '',
    'designation': '',
    'department': '',
    'joiningDate': '',
    'qualification': '',
    'address': '',
  };

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  // Fetch teacher data from Firestore
  Future<void> _fetchTeacherData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      isProfileFound = false;
    });

    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        setState(() {
          errorMessage = 'No user is currently logged in';
          isLoading = false;
        });
        return;
      }

      // First try to fetch from users collection to get the teacherId
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String teacherId = '';
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        teacherId = userData['teacherId'] ?? '';
      }
      
      // If we have a teacherId, use it to fetch the complete teacher profile
      if (teacherId.isNotEmpty) {
        DocumentSnapshot teacherDoc = await _firestore
            .collection('teachers')
            .doc(teacherId)
            .get();
            
        if (teacherDoc.exists) {
          Map<String, dynamic> data = teacherDoc.data() as Map<String, dynamic>;
          
          setState(() {
            teacherData = {
              'name': data['name'] ?? '',
              'email': data['email'] ?? currentUser.email ?? '',
              'phone': data['contact'] ?? '',
              'employeeId': data['teacherId'] ?? '',
              'designation': data['position'] ?? '',
              'department': data['department'] ?? '',
              'joiningDate': data['joiningDate'] ?? '',
              'qualification': data['qualification'] ?? '',
              'address': data['address'] ?? '',
            };
            isLoading = false;
            isProfileFound = true;
          });
          return;
        }
      }
      
      // Fallback to check teachers collection directly with UID
      DocumentSnapshot teacherDocByUid = await _firestore
          .collection('teachers')
          .doc(currentUser.uid)
          .get();
          
      if (teacherDocByUid.exists) {
        Map<String, dynamic> data = teacherDocByUid.data() as Map<String, dynamic>;
        
        setState(() {
          teacherData = {
            'name': data['name'] ?? '',
            'email': data['email'] ?? currentUser.email ?? '',
            'phone': data['contact'] ?? data['phone'] ?? '',
            'employeeId': data['teacherId'] ?? data['employeeId'] ?? '',
            'designation': data['position'] ?? data['designation'] ?? '',
            'department': data['department'] ?? '',
            'joiningDate': data['joiningDate'] ?? '',
            'qualification': data['qualification'] ?? '',
            'address': data['address'] ?? '',
          };
          isLoading = false;
          isProfileFound = true;
        });
        return;
      }
      
      // If still no profile, check if there's a pending approval
      DocumentSnapshot pendingDoc = await _firestore
          .collection('pendingApprovals')
          .doc(currentUser.uid)
          .get();
      
      if (pendingDoc.exists) {
        Map<String, dynamic> data = pendingDoc.data() as Map<String, dynamic>;
        
        setState(() {
          teacherData = {
            'name': data['name'] ?? '',
            'email': data['email'] ?? currentUser.email ?? '',
            'phone': data['contact'] ?? '',
            'employeeId': data['teacherId'] ?? '',
            'designation': data['position'] ?? '',
            'department': data['department'] ?? '',
            'joiningDate': '',
            'qualification': '',
            'address': '',
          };
          isLoading = false;
          isProfileFound = false;
          errorMessage = 'Your account is pending approval by an administrator.';
        });
        return;
      }
      
      // If we got here, no profile was found
      setState(() {
        errorMessage = 'Teacher profile not found. Please ensure you have registered correctly.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching profile: $e';
        isLoading = false;
      });
    }
  }

  // Save updated teacher data to Firestore
  Future<void> _saveTeacherData() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is currently logged in')),
        );
        return;
      }
      
      // First get the user document to determine the teacherId
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      String teacherId = '';
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        teacherId = userData['teacherId'] ?? '';
      }
      
      // If we have a teacherId, use it to update the teacher document
      if (teacherId.isNotEmpty) {
        // Create a map with the Firebase field names
        Map<String, dynamic> dataToSave = {
          'name': teacherData['name'],
          'email': teacherData['email'],
          'contact': teacherData['phone'],
          'teacherId': teacherData['employeeId'],
          'position': teacherData['designation'],
          'department': teacherData['department'],
          'joiningDate': teacherData['joiningDate'],
          'qualification': teacherData['qualification'],
          'address': teacherData['address'],
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('teachers')
            .doc(teacherId)
            .update(dataToSave);
            
        // Also update the name in the users collection
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'name': teacherData['name'],
              'department': teacherData['department'],
            });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        return;
      }
      
      // If no teacherId found, try to update the teacher document directly with UID
      DocumentSnapshot teacherDocCheck = await _firestore
          .collection('teachers')
          .doc(currentUser.uid)
          .get();
          
      if (teacherDocCheck.exists) {
        // Create a map with the Firebase field names
        Map<String, dynamic> dataToSave = {
          'name': teacherData['name'],
          'email': teacherData['email'],
          'phone': teacherData['phone'],
          'teacherId': teacherData['employeeId'],
          'position': teacherData['designation'],
          'department': teacherData['department'],
          'joiningDate': teacherData['joiningDate'],
          'qualification': teacherData['qualification'],
          'address': teacherData['address'],
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('teachers')
            .doc(currentUser.uid)
            .update(dataToSave);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        return;
      }
      
      // If we got here, we couldn't update the profile
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to locate your teacher profile')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  // Create a new teacher profile
  Future<void> _createTeacherProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is currently logged in')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // First set the email from the current user
      teacherData['email'] = currentUser.email ?? '';
      
      // Create a map with the Firebase field names
      Map<String, dynamic> dataToSave = {
        'name': teacherData['name'],
        'email': teacherData['email'],
        'contact': teacherData['phone'],
        'teacherId': teacherData['employeeId'],
        'position': teacherData['designation'],
        'department': teacherData['department'],
        'joiningDate': teacherData['joiningDate'],
        'qualification': teacherData['qualification'],
        'address': teacherData['address'],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': currentUser.uid,
      };
      
      // Create a new document in the teachers collection - use the employeeId as document ID
      String docId = teacherData['employeeId'].isNotEmpty ? 
          teacherData['employeeId'] : currentUser.uid;
      
      await _firestore
          .collection('teachers')
          .doc(docId)
          .set(dataToSave);
      
      // Also create/update entry in users collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'name': teacherData['name'],
            'email': teacherData['email'],
            'role': 'teacher',
            'teacherId': teacherData['employeeId'],
            'department': teacherData['department'],
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile created successfully')),
      );
      
      // Refresh the profile data
      _fetchTeacherData();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error creating profile: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: $e')),
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
              _buildAppBar(context),
              if (isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                )
              else if (errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTeacherData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Try Again'),
                        ),
                        SizedBox(height: 16),
                        // Option to create a new profile
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isEditing = true;
                              errorMessage = '';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF1B5E20),
                            side: BorderSide(color: Color(0xFF1B5E20)),
                          ),
                          child: Text('Create New Profile'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        _buildProfileDetails(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: !isProfileFound && isEditing
          ? FloatingActionButton(
              onPressed: _createTeacherProfile,
              backgroundColor: Color(0xFF1B5E20),
              child: Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Color(0xFF1B5E20),
            ),
            onPressed: () {
              setState(() {
                if (isEditing) {
                  // Save profile changes
                  if (isProfileFound) {
                    _saveTeacherData();
                  } else {
                    _createTeacherProfile();
                  }
                }
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Get first letter of name for avatar
    String initial = teacherData['name'].isNotEmpty 
        ? teacherData['name'][0].toUpperCase() 
        : 'T';
        
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF1B5E20),
                child: Text(
                  initial,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (isEditing) 
            TextFormField(
              initialValue: teacherData['name'],
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  teacherData['name'] = value;
                });
              },
            )
          else
            Text(
              teacherData['name'] != '' ? teacherData['name'] : 'No Name',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          SizedBox(height: 4),
          if (isEditing)
            TextFormField(
              initialValue: teacherData['designation'],
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              decoration: InputDecoration(
                hintText: 'Enter your designation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  teacherData['designation'] = value;
                });
              },
            )
          else
            Text(
              teacherData['designation'] != '' ? teacherData['designation'] : 'No Designation',
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
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSection(
            'Personal Information',
            [
              _buildInfoTile('Email', teacherData['email'] ?? '', Icons.email),
              _buildInfoTile('Phone', teacherData['phone'] ?? '', Icons.phone),
              _buildInfoTile('Address', teacherData['address'] ?? '', Icons.location_on),
            ],
          ),
          SizedBox(height: 24),
          _buildSection(
            'Professional Information',
            [
              _buildInfoTile('Employee ID', teacherData['employeeId'] ?? '', Icons.badge),
              _buildInfoTile('Department', teacherData['department'] ?? '', Icons.business),
              _buildInfoTile('Joining Date', teacherData['joiningDate'] ?? '', Icons.calendar_today),
              _buildInfoTile('Qualification', teacherData['qualification'] ?? '', Icons.school),
            ],
          ),
          SizedBox(height: 24),
          if (!isEditing && isProfileFound) ...[
            _buildActionButton(
              'Change Password',
              Icons.lock_outline,
              () {
                _showChangePasswordDialog(context);
              },
            ),
            SizedBox(height: 12),
            _buildActionButton(
              'Privacy Settings',
              Icons.privacy_tip_outlined,
              () {
                // Add privacy settings logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Privacy settings functionality to be implemented')),
                );
              },
            ),
          ],
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  label,
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                if (isEditing)
                  TextFormField(
                    initialValue: value,
                    style: GoogleFonts.raleway(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        // Update the value in teacherData
                        switch (label) {
                          case 'Email':
                            teacherData['email'] = newValue;
                            break;
                          case 'Phone':
                            teacherData['phone'] = newValue;
                            break;
                          case 'Address':
                            teacherData['address'] = newValue;
                            break;
                          case 'Employee ID':
                            teacherData['employeeId'] = newValue;
                            break;
                          case 'Department':
                            teacherData['department'] = newValue;
                            break;
                          case 'Joining Date':
                            teacherData['joiningDate'] = newValue;
                            break;
                          case 'Qualification':
                            teacherData['qualification'] = newValue;
                            break;
                        }
                      });
                    },
                  )
                else
                  Text(
                    value.isEmpty ? 'Not specified' : value,
                    style: GoogleFonts.raleway(fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Color(0xFF1B5E20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFF1B5E20), size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.raleway(
                color: Color(0xFF1B5E20),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show change password dialog
  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // For responsive dialog sizing
            final screenSize = MediaQuery.of(context).size;
            final dialogWidth = screenSize.width > 600 ? 500.0 : screenSize.width * 0.9;
            
            return AlertDialog(
              title: Text(
                'Change Password',
                style: GoogleFonts.playfairDisplay(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: dialogWidth,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF1B5E20)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF1B5E20)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock_clock, color: Color(0xFF1B5E20)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading 
                    ? null 
                    : () {
                        Navigator.of(context).pop();
                      },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.raleway(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading 
                    ? null 
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });
                          
                          try {
                            // Update password using Firebase Auth
                            User? user = _auth.currentUser;
                            
                            if (user != null && user.email != null) {
                              // Re-authenticate the user
                              AuthCredential credential = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPasswordController.text,
                              );
                              
                              await user.reauthenticateWithCredential(credential);
                              
                              // Update the password
                              await user.updatePassword(newPasswordController.text);
                              
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            
                            String errorMessage = 'Password update failed';
                            
                            if (e is FirebaseAuthException) {
                              switch (e.code) {
                                case 'wrong-password':
                                  errorMessage = 'Current password is incorrect';
                                  break;
                                case 'weak-password':
                                  errorMessage = 'New password is too weak';
                                  break;
                                default:
                                  errorMessage = 'Error: ${e.message}';
                              }
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class TeacherProfile extends StatefulWidget {
//   @override
//   _TeacherProfileState createState() => _TeacherProfileState();
// }

// class _TeacherProfileState extends State<TeacherProfile> {
//   bool isEditing = false;
//   bool isLoading = true;
//   String errorMessage = '';
//   bool isProfileFound = false;
  
//   // Map to store teacher data
//   Map<String, dynamic> teacherData = {
//     'name': '',
//     'email': '',
//     'phone': '',
//     'employeeId': '',
//     'designation': '',
//     'department': '',
//     'joiningDate': '',
//     'qualification': '',
//     'address': '',
//   };

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _fetchTeacherData();
//   }

//   // Fetch teacher data from Firestore
//   Future<void> _fetchTeacherData() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//       isProfileFound = false;
//     });

//     try {
//       // Get current user
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         setState(() {
//           errorMessage = 'No user is currently logged in';
//           isLoading = false;
//         });
//         return;
//       }

//       // First try to fetch from users collection to get the teacherId
//       DocumentSnapshot userDoc = await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();

//       String teacherId = '';
      
//       if (userDoc.exists) {
//         Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//         teacherId = userData['teacherId'] ?? '';
//       }
      
//       // If we have a teacherId, use it to fetch the complete teacher profile
//       if (teacherId.isNotEmpty) {
//         DocumentSnapshot teacherDoc = await _firestore
//             .collection('teachers')
//             .doc(teacherId)
//             .get();
            
//         if (teacherDoc.exists) {
//           Map<String, dynamic> data = teacherDoc.data() as Map<String, dynamic>;
          
//           setState(() {
//             teacherData = {
//               'name': data['name'] ?? '',
//               'email': data['email'] ?? currentUser.email ?? '',
//               'phone': data['contact'] ?? '',
//               'employeeId': data['teacherId'] ?? '',
//               'designation': data['position'] ?? '',
//               'department': data['department'] ?? '',
//               'joiningDate': data['joiningDate'] ?? '',
//               'qualification': data['qualification'] ?? '',
//               'address': data['address'] ?? '',
//             };
//             isLoading = false;
//             isProfileFound = true;
//           });
//           return;
//         }
//       }
      
//       // Fallback to check teachers collection directly with UID
//       DocumentSnapshot teacherDocByUid = await _firestore
//           .collection('teachers')
//           .doc(currentUser.uid)
//           .get();
          
//       if (teacherDocByUid.exists) {
//         Map<String, dynamic> data = teacherDocByUid.data() as Map<String, dynamic>;
        
//         setState(() {
//           teacherData = {
//             'name': data['name'] ?? '',
//             'email': data['email'] ?? currentUser.email ?? '',
//             'phone': data['contact'] ?? data['phone'] ?? '',
//             'employeeId': data['teacherId'] ?? data['employeeId'] ?? '',
//             'designation': data['position'] ?? data['designation'] ?? '',
//             'department': data['department'] ?? '',
//             'joiningDate': data['joiningDate'] ?? '',
//             'qualification': data['qualification'] ?? '',
//             'address': data['address'] ?? '',
//           };
//           isLoading = false;
//           isProfileFound = true;
//         });
//         return;
//       }
      
//       // If still no profile, check if there's a pending approval
//       DocumentSnapshot pendingDoc = await _firestore
//           .collection('pendingApprovals')
//           .doc(currentUser.uid)
//           .get();
      
//       if (pendingDoc.exists) {
//         Map<String, dynamic> data = pendingDoc.data() as Map<String, dynamic>;
        
//         setState(() {
//           teacherData = {
//             'name': data['name'] ?? '',
//             'email': data['email'] ?? currentUser.email ?? '',
//             'phone': data['contact'] ?? '',
//             'employeeId': data['teacherId'] ?? '',
//             'designation': data['position'] ?? '',
//             'department': data['department'] ?? '',
//             'joiningDate': '',
//             'qualification': '',
//             'address': '',
//           };
//           isLoading = false;
//           isProfileFound = false;
//           errorMessage = 'Your account is pending approval by an administrator.';
//         });
//         return;
//       }
      
//       // If we got here, no profile was found
//       setState(() {
//         errorMessage = 'Teacher profile not found. Please ensure you have registered correctly.';
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error fetching profile: $e';
//         isLoading = false;
//       });
//     }
//   }

//   // Save updated teacher data to Firestore
//   Future<void> _saveTeacherData() async {
//     try {
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('No user is currently logged in')),
//         );
//         return;
//       }
      
//       // First get the user document to determine the teacherId
//       DocumentSnapshot userDoc = await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();
          
//       String teacherId = '';
      
//       if (userDoc.exists) {
//         Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//         teacherId = userData['teacherId'] ?? '';
//       }
      
//       // If we have a teacherId, use it to update the teacher document
//       if (teacherId.isNotEmpty) {
//         // Create a map with the Firebase field names
//         Map<String, dynamic> dataToSave = {
//           'name': teacherData['name'],
//           'email': teacherData['email'],
//           'contact': teacherData['phone'],
//           'teacherId': teacherData['employeeId'],
//           'position': teacherData['designation'],
//           'department': teacherData['department'],
//           'joiningDate': teacherData['joiningDate'],
//           'qualification': teacherData['qualification'],
//           'address': teacherData['address'],
//           'updatedAt': FieldValue.serverTimestamp(),
//         };

//         await _firestore
//             .collection('teachers')
//             .doc(teacherId)
//             .update(dataToSave);
            
//         // Also update the name in the users collection
//         await _firestore
//             .collection('users')
//             .doc(currentUser.uid)
//             .update({
//               'name': teacherData['name'],
//               'department': teacherData['department'],
//             });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Profile updated successfully')),
//         );
//         return;
//       }
      
//       // If no teacherId found, try to update the teacher document directly with UID
//       DocumentSnapshot teacherDocCheck = await _firestore
//           .collection('teachers')
//           .doc(currentUser.uid)
//           .get();
          
//       if (teacherDocCheck.exists) {
//         // Create a map with the Firebase field names
//         Map<String, dynamic> dataToSave = {
//           'name': teacherData['name'],
//           'email': teacherData['email'],
//           'phone': teacherData['phone'],
//           'teacherId': teacherData['employeeId'],
//           'position': teacherData['designation'],
//           'department': teacherData['department'],
//           'joiningDate': teacherData['joiningDate'],
//           'qualification': teacherData['qualification'],
//           'address': teacherData['address'],
//           'updatedAt': FieldValue.serverTimestamp(),
//         };

//         await _firestore
//             .collection('teachers')
//             .doc(currentUser.uid)
//             .update(dataToSave);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Profile updated successfully')),
//         );
//         return;
//       }
      
//       // If we got here, we couldn't update the profile
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: Unable to locate your teacher profile')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: $e')),
//       );
//     }
//   }

//   // Create a new teacher profile
//   Future<void> _createTeacherProfile() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('No user is currently logged in')),
//         );
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }

//       // First set the email from the current user
//       teacherData['email'] = currentUser.email ?? '';
      
//       // Create a map with the Firebase field names
//       Map<String, dynamic> dataToSave = {
//         'name': teacherData['name'],
//         'email': teacherData['email'],
//         'contact': teacherData['phone'],
//         'teacherId': teacherData['employeeId'],
//         'position': teacherData['designation'],
//         'department': teacherData['department'],
//         'joiningDate': teacherData['joiningDate'],
//         'qualification': teacherData['qualification'],
//         'address': teacherData['address'],
//         'status': 'active',
//         'createdAt': FieldValue.serverTimestamp(),
//         'uid': currentUser.uid,
//       };
      
//       // Create a new document in the teachers collection - use the employeeId as document ID
//       String docId = teacherData['employeeId'].isNotEmpty ? 
//           teacherData['employeeId'] : currentUser.uid;
      
//       await _firestore
//           .collection('teachers')
//           .doc(docId)
//           .set(dataToSave);
      
//       // Also create/update entry in users collection
//       await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .set({
//             'name': teacherData['name'],
//             'email': teacherData['email'],
//             'role': 'teacher',
//             'teacherId': teacherData['employeeId'],
//             'department': teacherData['department'],
//             'createdAt': FieldValue.serverTimestamp(),
//             'isActive': true,
//           }, SetOptions(merge: true));
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Profile created successfully')),
//       );
      
//       // Refresh the profile data
//       _fetchTeacherData();
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Error creating profile: $e';
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error creating profile: $e')),
//       );
//     }
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
//               _buildAppBar(context),
//               if (isLoading)
//                 Expanded(
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                 )
//               else if (errorMessage.isNotEmpty)
//                 Expanded(
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           size: 60,
//                           color: Colors.red[400],
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           errorMessage,
//                           style: TextStyle(color: Colors.red),
//                           textAlign: TextAlign.center,
//                         ),
//                         SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _fetchTeacherData,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFF1B5E20),
//                             foregroundColor: Colors.white,
//                           ),
//                           child: Text('Try Again'),
//                         ),
//                         SizedBox(height: 16),
//                         // Option to create a new profile
//                         OutlinedButton(
//                           onPressed: () {
//                             setState(() {
//                               isEditing = true;
//                               errorMessage = '';
//                             });
//                           },
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Color(0xFF1B5E20),
//                             side: BorderSide(color: Color(0xFF1B5E20)),
//                           ),
//                           child: Text('Create New Profile'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               else
//                 Expanded(
//                   child: SingleChildScrollView(
//                     physics: AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       children: [
//                         _buildProfileHeader(),
//                         _buildProfileDetails(),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: !isProfileFound && isEditing
//           ? FloatingActionButton(
//               onPressed: _createTeacherProfile,
//               backgroundColor: Color(0xFF1B5E20),
//               child: Icon(Icons.save),
//             )
//           : null,
//     );
//   }

//   Widget _buildAppBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//             onPressed: () => Navigator.pop(context),
//           ),
//           Expanded(
//             child: Text(
//               'Profile',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(
//               isEditing ? Icons.check : Icons.edit,
//               color: Color(0xFF1B5E20),
//             ),
//             onPressed: () {
//               setState(() {
//                 if (isEditing) {
//                   // Save profile changes
//                   if (isProfileFound) {
//                     _saveTeacherData();
//                   } else {
//                     _createTeacherProfile();
//                   }
//                 }
//                 isEditing = !isEditing;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     // Get first letter of name for avatar
//     String initial = teacherData['name'].isNotEmpty 
//         ? teacherData['name'][0].toUpperCase() 
//         : 'T';
        
//     return Container(
//       padding: EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               CircleAvatar(
//                 radius: 60,
//                 backgroundColor: Color(0xFF1B5E20),
//                 child: Text(
//                   initial,
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 48,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               if (isEditing)
//                 Positioned(
//                   right: 0,
//                   bottom: 0,
//                   child: Container(
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Color(0xFF1B5E20),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.camera_alt,
//                       color: Colors.white,
//                       size: 20,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           SizedBox(height: 16),
//           if (isEditing) 
//             TextFormField(
//               initialValue: teacherData['name'],
//               textAlign: TextAlign.center,
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Enter your name',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   teacherData['name'] = value;
//                 });
//               },
//             )
//           else
//             Text(
//               teacherData['name'] != '' ? teacherData['name'] : 'No Name',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//             ),
//           SizedBox(height: 4),
//           if (isEditing)
//             TextFormField(
//               initialValue: teacherData['designation'],
//               textAlign: TextAlign.center,
//               style: GoogleFonts.raleway(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Enter your designation',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   teacherData['designation'] = value;
//                 });
//               },
//             )
//           else
//             Text(
//               teacherData['designation'] != '' ? teacherData['designation'] : 'No Designation',
//               style: GoogleFonts.raleway(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileDetails() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         children: [
//           _buildSection(
//             'Personal Information',
//             [
//               _buildInfoTile('Email', teacherData['email'] ?? '', Icons.email),
//               _buildInfoTile('Phone', teacherData['phone'] ?? '', Icons.phone),
//               _buildInfoTile('Address', teacherData['address'] ?? '', Icons.location_on),
//             ],
//           ),
//           SizedBox(height: 24),
//           _buildSection(
//             'Professional Information',
//             [
//               _buildInfoTile('Employee ID', teacherData['employeeId'] ?? '', Icons.badge),
//               _buildInfoTile('Department', teacherData['department'] ?? '', Icons.business),
//               _buildInfoTile('Joining Date', teacherData['joiningDate'] ?? '', Icons.calendar_today),
//               _buildInfoTile('Qualification', teacherData['qualification'] ?? '', Icons.school),
//             ],
//           ),
//           SizedBox(height: 24),
//           if (!isEditing && isProfileFound) ...[
//             _buildActionButton(
//               'Change Password',
//               Icons.lock_outline,
//               () {
//                 // Add change password logic
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Password change functionality to be implemented')),
//                 );
//               },
//             ),
//             SizedBox(height: 12),
//             _buildActionButton(
//               'Privacy Settings',
//               Icons.privacy_tip_outlined,
//               () {
//                 // Add privacy settings logic
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Privacy settings functionality to be implemented')),
//                 );
//               },
//             ),
//           ],
//           SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildSection(String title, List<Widget> children) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Colors.grey.shade200),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//             ),
//             SizedBox(height: 16),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Color(0xFF1B5E20).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               color: Color(0xFF1B5E20),
//               size: 20,
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
//                 if (isEditing)
//                   TextFormField(
//                     initialValue: value,
//                     style: GoogleFonts.raleway(fontSize: 14),
//                     decoration: InputDecoration(
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onChanged: (newValue) {
//                       setState(() {
//                         // Update the value in teacherData
//                         switch (label) {
//                           case 'Email':
//                             teacherData['email'] = newValue;
//                             break;
//                           case 'Phone':
//                             teacherData['phone'] = newValue;
//                             break;
//                           case 'Address':
//                             teacherData['address'] = newValue;
//                             break;
//                           case 'Employee ID':
//                             teacherData['employeeId'] = newValue;
//                             break;
//                           case 'Department':
//                             teacherData['department'] = newValue;
//                             break;
//                           case 'Joining Date':
//                             teacherData['joiningDate'] = newValue;
//                             break;
//                           case 'Qualification':
//                             teacherData['qualification'] = newValue;
//                             break;
//                         }
//                       });
//                     },
//                   )
//                 else
//                   Text(
//                     value.isEmpty ? 'Not specified' : value,
//                     style: GoogleFonts.raleway(fontSize: 14),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton(
//         onPressed: onPressed,
//         style: OutlinedButton.styleFrom(
//           padding: EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           side: BorderSide(color: Color(0xFF1B5E20)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Color(0xFF1B5E20), size: 20),
//             SizedBox(width: 8),
//             Text(
//               label,
//               style: GoogleFonts.raleway(
//                 color: Color(0xFF1B5E20),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
