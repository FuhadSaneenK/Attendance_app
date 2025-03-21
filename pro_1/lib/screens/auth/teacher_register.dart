import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/services/authentication.dart';
import 'package:pro_1/screens/auth/teacher_login.dart';


class TeacherRegistrationPage extends StatefulWidget {
  @override
  _TeacherRegistrationPageState createState() => _TeacherRegistrationPageState();
}

class _TeacherRegistrationPageState extends State<TeacherRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

 Future<void> _register() async {
  // First validate form
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  // Check if passwords match
  if (_passwordController.text != _confirmPasswordController.text) {
    setState(() {
      _errorMessage = 'Passwords do not match';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    // Call your authentication service to register
    AuthResult result = await _authService.registerTeacher(
      name: _nameController.text,
      email: _emailController.text,
      contact: _contactController.text,
      teacherId: _teacherIdController.text,
      department: _departmentController.text,
      password: _passwordController.text,
    );

    if (result.success) {
      // Show success message about pending approval
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Registration Submitted',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your registration has been submitted successfully!',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 16),
                Text(
                  'Your account is pending approval from the administrator. You will be notified via email once your account has been approved.',
                  style: GoogleFonts.raleway(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherLoginPage(),
                    ),
                  );
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Registration failed: ${e.toString()}';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _teacherIdController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                  Text(
                    'Faculty Portal',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your faculty account',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Registration Form
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Registration',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Full Name Field
                          Text(
                            'Full Name',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Color(0xFF1B5E20),
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Email Field
                          Text(
                            'Email',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Color(0xFF1B5E20),
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Contact Number
                          Text(
                            'Contact Number',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _contactController,
                            decoration: InputDecoration(
                              hintText: 'Enter your contact number',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: Color(0xFF1B5E20),
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your contact number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Teacher ID
                          Text(
                            'Teacher ID',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _teacherIdController,
                            decoration: InputDecoration(
                              hintText: 'Enter your teacher ID',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: Color(0xFF1B5E20),
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your teacher ID';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Department
                          Text(
                            'Department',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _departmentController,
                            decoration: InputDecoration(
                              hintText: 'Enter your department',
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                color: Color(0xFF1B5E20),
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your department';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Password
                          Text(
                            'Password',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Create a password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Color(0xFF1B5E20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Confirm Password
                          Text(
                            'Confirm Password',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'Confirm your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Color(0xFF1B5E20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          // Display error message if there is one
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            
                          SizedBox(height: 24),
                          
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Register',
                                      style: GoogleFonts.raleway(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Already have an account section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherLoginPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF1B5E20),
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                          ),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Back button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_outlined, size: 18),
                    label: Text(
                      'Back to Selection',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}