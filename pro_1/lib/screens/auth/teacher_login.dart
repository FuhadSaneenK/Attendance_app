import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/services/authentication.dart';
import 'package:pro_1/screens/auth/teacher_register.dart';
import 'package:pro_1/screens/teacher/teacher_homepage.dart';

class TeacherLoginPage extends StatefulWidget {
  @override
  _TeacherLoginPageState createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController(); // Controller for teacher ID
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isGoogleSigningIn = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    AuthResult result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: 'teacher',
    );

    if (result.success) {
      // Navigate to TeacherHomePage on successful verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherHomePage(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  // Show dialog to enter teacher ID for Google Sign-In
  Future<void> _showTeacherIdDialog() async {
    _teacherIdController.clear(); // Clear previous input
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Enter Teacher ID',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please enter your teacher ID to continue with Google Sign-In.\nNote: You must have registered using email/password first.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _teacherIdController,
                  decoration: InputDecoration(
                    labelText: 'Teacher ID',
                    hintText: 'Enter your approved teacher ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Continue',
                style: TextStyle(color: Color(0xFF1B5E20)),
              ),
              onPressed: () {
                if (_teacherIdController.text.trim().isEmpty) {
                  // Show error if teacher ID is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Teacher ID is required')),
                  );
                } else {
                  Navigator.of(context).pop();
                  _proceedWithGoogleSignIn();
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _proceedWithGoogleSignIn() async {
    setState(() {
      _isGoogleSigningIn = true;
      _errorMessage = '';
    });

    try {
      // Pass the teacher ID to the signInWithGoogle method
      AuthResult result = await _authService.signInWithGoogle(
        expectedRole: 'teacher',
        teacherId: _teacherIdController.text.trim(),
      );

      if (result.success) {
        // Navigate to TeacherHomePage on successful verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherHomePage(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign in failed: $e';
      });
    } finally {
      setState(() {
        _isGoogleSigningIn = false;
      });
    }
  }
  
  // Modified to show teacher ID dialog first
  Future<void> _signInWithGoogle() async {
    await _showTeacherIdDialog();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For responsive design
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    
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
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0, 
                  vertical: isSmallScreen ? 24.0 : 32.0
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Faculty Portal',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your classes and resources',
                      style: GoogleFonts.raleway(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Login Form Section
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Sign In',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          Text(
                            'Email',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
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
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Password',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
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
                          ),
                          
                          // Display error message if there is one
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
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
                                      'Sign In',
                                      style: GoogleFonts.raleway(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Divider with OR
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGoogleSigningIn ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                elevation: 0,
                              ),
                              icon: _isGoogleSigningIn
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey[600]!,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.g_mobiledata, // Google icon from Flutter icons
                                      size: 24,
                                      color: Colors.red,
                                    ),
                              label: Text(
                                'Sign in with Google',
                                style: GoogleFonts.raleway(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          // Info about Google Sign-in restriction
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Note: Google Sign-in is only available for teachers who have already registered with email and password.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Additional Options Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12.0 : 16.0
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: isSmallScreen ? 8 : 16,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Navigate to forgot password
                            },
                            icon: Icon(Icons.lock_reset_outlined, size: isSmallScreen ? 16 : 18),
                            label: Text(
                              'Reset Password',
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF1B5E20),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherRegistrationPage(),
                                ),
                              );
                            },
                            icon: Icon(Icons.person_add_outlined, size: isSmallScreen ? 16 : 18),
                            label: Text(
                              'Register',
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF1B5E20),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.arrow_back_outlined, size: isSmallScreen ? 16 : 18),
                            label: Text(
                              'Back to Selection',
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF1B5E20),
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
        ),
      ),
    );
  }
}


















// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pro_1/services/authentication.dart';
// import 'package:pro_1/screens/auth/teacher_register.dart';
// import 'package:pro_1/screens/teacher/teacher_homepage.dart';

// class TeacherLoginPage extends StatefulWidget {
//   @override
//   _TeacherLoginPageState createState() => _TeacherLoginPageState();
// }

// class _TeacherLoginPageState extends State<TeacherLoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _teacherIdController = TextEditingController(); // New controller for teacher ID
//   final AuthService _authService = AuthService();
  
//   bool _isLoading = false;
//   bool _isGoogleSigningIn = false;
//   String _errorMessage = '';
//   bool _obscurePassword = true;

//   Future<void> _signIn() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     AuthResult result = await _authService.signInWithEmailAndPassword(
//       email: _emailController.text,
//       password: _passwordController.text,
//       expectedRole: 'teacher',
//     );

//     if (result.success) {
//       // Navigate to TeacherHomePage on successful verification
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => TeacherHomePage(),
//         ),
//       );
//     } else {
//       setState(() {
//         _errorMessage = result.errorMessage;
//       });
//     }

//     setState(() {
//       _isLoading = false;
//     });
//   }
  
//   // Show dialog to enter teacher ID for Google Sign-In
//   Future<void> _showTeacherIdDialog() async {
//     _teacherIdController.clear(); // Clear previous input
    
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Enter Teacher ID',
//             style: GoogleFonts.playfairDisplay(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Please enter your teacher ID to continue with Google Sign-In',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 16),
//                 TextField(
//                   controller: _teacherIdController,
//                   decoration: InputDecoration(
//                     labelText: 'Teacher ID',
//                     hintText: 'Enter your teacher ID',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(
//                 'Continue',
//                 style: TextStyle(color: Color(0xFF1B5E20)),
//               ),
//               onPressed: () {
//                 if (_teacherIdController.text.trim().isEmpty) {
//                   // Show error if teacher ID is empty
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Teacher ID is required')),
//                   );
//                 } else {
//                   Navigator.of(context).pop();
//                   _proceedWithGoogleSignIn();
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
  
//   Future<void> _proceedWithGoogleSignIn() async {
//     setState(() {
//       _isGoogleSigningIn = true;
//       _errorMessage = '';
//     });

//     try {
//       // Pass the teacher ID to the signInWithGoogle method
//       AuthResult result = await _authService.signInWithGoogle(
//         expectedRole: 'teacher',
//         teacherId: _teacherIdController.text.trim(),
//       );

//       if (result.success) {
//         // Navigate to TeacherHomePage on successful verification
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TeacherHomePage(),
//           ),
//         );
//       } else {
//         setState(() {
//           _errorMessage = result.errorMessage;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Google sign in failed: $e';
//       });
//     } finally {
//       setState(() {
//         _isGoogleSigningIn = false;
//       });
//     }
//   }
  
//   // Modified to show teacher ID dialog first
//   Future<void> _signInWithGoogle() async {
//     await _showTeacherIdDialog();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _teacherIdController.dispose(); // Dispose the new controller
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // For responsive design
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isSmallScreen = screenWidth < 600;
    
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
//             ),
//             child: Container(
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
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 16.0 : 24.0, 
//                   vertical: isSmallScreen ? 24.0 : 32.0
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       'Faculty Portal',
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: isSmallScreen ? 24 : 28,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1B5E20),
//                         letterSpacing: 0.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Manage your classes and resources',
//                       style: GoogleFonts.raleway(
//                         fontSize: isSmallScreen ? 14 : 16,
//                         color: Colors.grey[600],
//                         letterSpacing: 0.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: isSmallScreen ? 24 : 32),

//                     // Login Form Section
//                     Container(
//                       padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.06),
//                             blurRadius: 30,
//                             offset: Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Faculty Sign In',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: isSmallScreen ? 20 : 24,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           SizedBox(height: isSmallScreen ? 16 : 24),
//                           Text(
//                             'Email',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           TextField(
//                             controller: _emailController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter your email',
//                               prefixIcon: Icon(
//                                 Icons.email_outlined,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                               hintStyle: TextStyle(
//                                 color: Colors.grey[400],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             keyboardType: TextInputType.emailAddress,
//                           ),
//                           SizedBox(height: 20),
//                           Text(
//                             'Password',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           TextField(
//                             controller: _passwordController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter your password',
//                               prefixIcon: Icon(
//                                 Icons.lock_outline,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscurePassword 
//                                       ? Icons.visibility_outlined 
//                                       : Icons.visibility_off_outlined,
//                                   color: Colors.grey[400],
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _obscurePassword = !_obscurePassword;
//                                   });
//                                 },
//                               ),
//                               hintStyle: TextStyle(
//                                 color: Colors.grey[400],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             obscureText: _obscurePassword,
//                           ),
                          
//                           // Display error message if there is one
//                           if (_errorMessage.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 12.0),
//                               child: Text(
//                                 _errorMessage,
//                                 style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
                            
//                           SizedBox(height: 24),
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _isLoading ? null : _signIn,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Color(0xFF1B5E20),
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               child: _isLoading
//                                   ? SizedBox(
//                                       height: 20,
//                                       width: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     )
//                                   : Text(
//                                       'Sign In',
//                                       style: GoogleFonts.raleway(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                         letterSpacing: 1,
//                                       ),
//                                     ),
//                             ),
//                           ),
                          
//                           // Divider with OR
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 16.0),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Divider(
//                                     color: Colors.grey[300],
//                                     thickness: 1,
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                                   child: Text(
//                                     'OR',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: Divider(
//                                     color: Colors.grey[300],
//                                     thickness: 1,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
                          
//                           // Google Sign-In Button with local Google icon
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton.icon(
//                               onPressed: _isGoogleSigningIn ? null : _signInWithGoogle,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: Colors.black87,
//                                 padding: EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   side: BorderSide(color: Colors.grey[300]!),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               icon: _isGoogleSigningIn
//                                   ? SizedBox(
//                                       width: 24,
//                                       height: 24,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.grey[600]!,
//                                         ),
//                                       ),
//                                     )
//                                   : Icon(
//                                       Icons.g_mobiledata, // Google icon from Flutter icons
//                                       size: 24,
//                                       color: Colors.red,
//                                     ),
//                               label: Text(
//                                 'Sign in with Google',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
                    
//                     // Additional Options Section
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         vertical: isSmallScreen ? 12.0 : 16.0
//                       ),
//                       child: Wrap(
//                         alignment: WrapAlignment.center,
//                         spacing: isSmallScreen ? 8 : 16,
//                         runSpacing: 8,
//                         children: [
//                           TextButton.icon(
//                             onPressed: () {
//                               // Navigate to forgot password
//                             },
//                             icon: Icon(Icons.lock_reset_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Reset Password',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           TextButton.icon(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => TeacherRegistrationPage(),
//                                 ),
//                               );
//                             },
//                             icon: Icon(Icons.person_add_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Register',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           TextButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: Icon(Icons.arrow_back_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Back to Selection',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pro_1/services/authentication.dart';
// import 'package:pro_1/screens/auth/teacher_register.dart';
// import 'package:pro_1/screens/teacher/teacher_homepage.dart';

// class TeacherLoginPage extends StatefulWidget {
//   @override
//   _TeacherLoginPageState createState() => _TeacherLoginPageState();
// }

// class _TeacherLoginPageState extends State<TeacherLoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final AuthService _authService = AuthService();
  
//   bool _isLoading = false;
//   bool _isGoogleSigningIn = false;
//   String _errorMessage = '';
//   bool _obscurePassword = true;

//   Future<void> _signIn() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     AuthResult result = await _authService.signInWithEmailAndPassword(
//       email: _emailController.text,
//       password: _passwordController.text,
//       expectedRole: 'teacher',
//     );

//     if (result.success) {
//       // Navigate to TeacherHomePage on successful verification
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => TeacherHomePage(),
//         ),
//       );
//     } else {
//       setState(() {
//         _errorMessage = result.errorMessage;
//       });
//     }

//     setState(() {
//       _isLoading = false;
//     });
//   }
  
//   Future<void> _signInWithGoogle() async {
//     setState(() {
//       _isGoogleSigningIn = true;
//       _errorMessage = '';
//     });

//     try {
//       // This would need to be implemented in your AuthService
//       AuthResult result = await _authService.signInWithGoogle(
//         expectedRole: 'teacher',
//       );

//       if (result.success) {
//         // Navigate to TeacherHomePage on successful verification
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TeacherHomePage(),
//           ),
//         );
//       } else {
//         setState(() {
//           _errorMessage = result.errorMessage;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Google sign in failed: $e';
//       });
//     } finally {
//       setState(() {
//         _isGoogleSigningIn = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // For responsive design
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isSmallScreen = screenWidth < 600;
    
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
//             ),
//             child: Container(
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
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isSmallScreen ? 16.0 : 24.0, 
//                   vertical: isSmallScreen ? 24.0 : 32.0
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       'Faculty Portal',
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: isSmallScreen ? 24 : 28,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1B5E20),
//                         letterSpacing: 0.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Manage your classes and resources',
//                       style: GoogleFonts.raleway(
//                         fontSize: isSmallScreen ? 14 : 16,
//                         color: Colors.grey[600],
//                         letterSpacing: 0.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: isSmallScreen ? 24 : 32),

//                     // Login Form Section
//                     Container(
//                       padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.06),
//                             blurRadius: 30,
//                             offset: Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Faculty Sign In',
//                             style: GoogleFonts.playfairDisplay(
//                               fontSize: isSmallScreen ? 20 : 24,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           SizedBox(height: isSmallScreen ? 16 : 24),
//                           Text(
//                             'Email',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           TextField(
//                             controller: _emailController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter your email',
//                               prefixIcon: Icon(
//                                 Icons.email_outlined,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                               hintStyle: TextStyle(
//                                 color: Colors.grey[400],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             keyboardType: TextInputType.emailAddress,
//                           ),
//                           SizedBox(height: 20),
//                           Text(
//                             'Password',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           TextField(
//                             controller: _passwordController,
//                             decoration: InputDecoration(
//                               hintText: 'Enter your password',
//                               prefixIcon: Icon(
//                                 Icons.lock_outline,
//                                 color: Color(0xFF1B5E20),
//                               ),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscurePassword 
//                                       ? Icons.visibility_outlined 
//                                       : Icons.visibility_off_outlined,
//                                   color: Colors.grey[400],
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _obscurePassword = !_obscurePassword;
//                                   });
//                                 },
//                               ),
//                               hintStyle: TextStyle(
//                                 color: Colors.grey[400],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             obscureText: _obscurePassword,
//                           ),
                          
//                           // Display error message if there is one
//                           if (_errorMessage.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 12.0),
//                               child: Text(
//                                 _errorMessage,
//                                 style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
                            
//                           SizedBox(height: 24),
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _isLoading ? null : _signIn,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Color(0xFF1B5E20),
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               child: _isLoading
//                                   ? SizedBox(
//                                       height: 20,
//                                       width: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     )
//                                   : Text(
//                                       'Sign In',
//                                       style: GoogleFonts.raleway(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                         letterSpacing: 1,
//                                       ),
//                                     ),
//                             ),
//                           ),
                          
//                           // Divider with OR
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 16.0),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Divider(
//                                     color: Colors.grey[300],
//                                     thickness: 1,
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                                   child: Text(
//                                     'OR',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: Divider(
//                                     color: Colors.grey[300],
//                                     thickness: 1,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
                          
//                           // Google Sign-In Button with local Google icon
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton.icon(
//                               onPressed: _isGoogleSigningIn ? null : _signInWithGoogle,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: Colors.black87,
//                                 padding: EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   side: BorderSide(color: Colors.grey[300]!),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               icon: _isGoogleSigningIn
//                                   ? SizedBox(
//                                       width: 24,
//                                       height: 24,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.grey[600]!,
//                                         ),
//                                       ),
//                                     )
//                                   : Icon(
//                                       Icons.g_mobiledata, // Google icon from Flutter icons
//                                       size: 24,
//                                       color: Colors.red,
//                                     ),
//                               label: Text(
//                                 'Sign in with Google',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
                    
//                     // Additional Options Section
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         vertical: isSmallScreen ? 12.0 : 16.0
//                       ),
//                       child: Wrap(
//                         alignment: WrapAlignment.center,
//                         spacing: isSmallScreen ? 8 : 16,
//                         runSpacing: 8,
//                         children: [
//                           TextButton.icon(
//                             onPressed: () {
//                               // Navigate to forgot password
//                             },
//                             icon: Icon(Icons.lock_reset_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Reset Password',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           TextButton.icon(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => TeacherRegistrationPage(),
//                                 ),
//                               );
//                             },
//                             icon: Icon(Icons.person_add_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Register',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                           TextButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: Icon(Icons.arrow_back_outlined, size: isSmallScreen ? 16 : 18),
//                             label: Text(
//                               'Back to Selection',
//                               style: GoogleFonts.raleway(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Color(0xFF1B5E20),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

