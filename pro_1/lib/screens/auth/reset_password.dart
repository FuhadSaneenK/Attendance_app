import 'package:flutter/material.dart';
import 'package:pro_1/services/authentication.dart';

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    AuthResult result = await _authService.resetPassword(_emailController.text);

    setState(() {
      _isLoading = false;
      _message = result.success 
          ? 'Password reset email sent. Please check your inbox.'
          : result.errorMessage;
      _isSuccess = result.success;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Forgot your password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF1B5E20),
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
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
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}