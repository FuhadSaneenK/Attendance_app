import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class SemesterPromotionPage extends StatefulWidget {
  const SemesterPromotionPage({Key? key}) : super(key: key);

  @override
  _SemesterPromotionPageState createState() => _SemesterPromotionPageState();
}

class _SemesterPromotionPageState extends State<SemesterPromotionPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isVerified = false;
  
  // Store semester data
  List<int> _semesters = [];
  Map<int, Map<String, dynamic>> _semesterData = {};
  Map<int, bool> _semesterSelectedForPromotion = {};
  
  // Admin verification
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  String _captchaText = '';
  bool _showVerificationError = false;
  
  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _fetchSemesterData();
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }
  
  // Generate random captcha text
  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    String captcha = '';
    for (var i = 0; i < 6; i++) {
      captcha += chars[rnd.nextInt(chars.length)];
    }
    setState(() {
      _captchaText = captcha;
    });
  }
  
  // Fetch all semester data including student counts, promotion status, etc.
  Future<void> _fetchSemesterData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Reset data structures
      _semesters = [];
      _semesterData = {};
      _semesterSelectedForPromotion = {};
      
      // Check each semester from 1 to 8
      for (int semester = 1; semester <= 8; semester++) {
        print("Checking semester $semester for promotion data");
        
        // Reference to semester document
        final semesterRef = firestore.collection('classes').doc('Sem$semester');
        final semesterDoc = await semesterRef.get();
        
        if (!semesterDoc.exists) {
          print("Semester $semester document doesn't exist");
          continue;
        }
        
        // Get all students in this semester
        final studentsCollection = await semesterRef.collection('students').get();
        
        if (studentsCollection.docs.isEmpty) {
          print("No students found in Semester $semester");
          continue;
        }
        
        // Count students by status
        int totalStudents = studentsCollection.docs.length;
        int passedStudents = 0;
        int failedStudents = 0;
        int notMarkedStudents = 0;
        
        // Track repeat students collection existence
        bool repeatCollectionExists = false;
        try {
          final repeatCollection = 
              await firestore.collection('classes').doc('Sem$semester-Repeat').get();
          repeatCollectionExists = repeatCollection.exists;
        } catch (e) {
          repeatCollectionExists = false;
        }
        
        // Process student records
        for (var studentDoc in studentsCollection.docs) {
          final studentData = studentDoc.data();
          if (studentData.containsKey('isPassed')) {
            if (studentData['isPassed'] == true) {
              passedStudents++;
            } else if (studentData['isPassed'] == false) {
              failedStudents++;
            }
          } else {
            notMarkedStudents++;
          }
        }
        
        // Add semester to list
        _semesters.add(semester);
        
        // Store semester data
        _semesterData[semester] = {
          'totalStudents': totalStudents,
          'passedStudents': passedStudents,
          'failedStudents': failedStudents,
          'notMarkedStudents': notMarkedStudents,
          'repeatCollectionExists': repeatCollectionExists,
          'canPromote': notMarkedStudents == 0 && totalStudents > 0,
        };
        
        // Initialize promotion selection status
        _semesterSelectedForPromotion[semester] = false;
      }
      
      // Sort semesters
      _semesters.sort();
      
      setState(() {
        _isLoading = false;
      });
      
      print("Finished fetching semester data for promotion. Found ${_semesters.length} semesters with students.");
      
    } catch (e) {
      print('Error fetching semester data for promotion: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading semester data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Verify admin credentials
  Future<void> _verifyAdmin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Check if admin password and captcha are correct
    // In a real app, you'd verify against Firebase Auth or another secure method
    final adminPassword = "admin123"; // Replace with actual secure verification
    
    if (_passwordController.text == adminPassword && 
        _captchaController.text.toUpperCase() == _captchaText) {
      setState(() {
        _isVerified = true;
        _showVerificationError = false;
      });
    } else {
      setState(() {
        _showVerificationError = true;
        _generateCaptcha();
      });
      
      _captchaController.clear();
    }
  }
  
  // Process student promotion for selected semesters
  Future<void> _processPromotion() async {
    // Check if any semester is selected
    final selectedSemesters = _semesterSelectedForPromotion.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (selectedSemesters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one semester to promote'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Confirm promotion
    bool confirmPromotion = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to promote students from the following semesters:'),
            SizedBox(height: 8),
            ...selectedSemesters.map((semester) => 
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4),
                child: Text(
                  '• Semester $semester (${_semesterData[semester]!['passedStudents']} passed, ${_semesterData[semester]!['failedStudents']} failed)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            ),
            SizedBox(height: 16),
            Text('This action cannot be undone. Are you sure you want to continue?',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: Text('CONFIRM'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmPromotion) return;
    
    // Start promotion process
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Process each selected semester
      for (int semester in selectedSemesters) {
        print("Processing promotion for Semester $semester");
        
        final semesterRef = firestore.collection('classes').doc('Sem$semester');
        
        // Get all students in this semester
        final QuerySnapshot studentsSnapshot = 
            await semesterRef.collection('students').get();
        
        // Process each student
        for (var studentDoc in studentsSnapshot.docs) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final studentId = studentDoc.id;
          final isPassed = studentData['isPassed'];
          
          if (isPassed == true) {
            // Handle passed students
            if (semester < 8) {
              // Move to next semester
              final nextSemesterRef = firestore.collection('classes').doc('Sem${semester + 1}');
              
              // Create next semester student document
              await nextSemesterRef.collection('students').doc(studentId).set({
                ...studentData,
                'semester': semester + 1,
                'isPassed': null, // Reset pass status for next semester
                'promotedOn': FieldValue.serverTimestamp(),
                'promotedFrom': semester,
              });
              
              // Delete from current semester
              await semesterRef.collection('students').doc(studentId).delete();
              
              print("Promoted student $studentId to Semester ${semester + 1}");
            } else {
              // Student completed all semesters, add to alumni
              // Extract admission year from admission number (assuming format like "2022XXX")
              String admissionNo = studentData['admissionNo'] ?? studentData['id'] ?? '';
              String yearPrefix = '';
              
              if (admissionNo.length >= 4) {
                yearPrefix = admissionNo.substring(0, 4);
              }
              
              // Add to alumni collection
              await firestore.collection('alumni').doc(studentId).set({
                ...studentData,
                'graduatedOn': FieldValue.serverTimestamp(),
                'yearBatch': yearPrefix,
                'completedSemesters': 8,
              });
              
              // Delete from current semester
              await semesterRef.collection('students').doc(studentId).delete();
              
              print("Added student $studentId to alumni");
            }
          } else if (isPassed == false) {
            // Handle failed students - move to repeat collection
            final repeatSemesterRef = firestore.collection('classes').doc('Sem$semester-Repeat');
            
            // Create repeat semester student document
            await repeatSemesterRef.collection('students').doc(studentId).set({
              ...studentData,
              'isPassed': null, // Reset pass status for repeated semester
              'markedForRepeat': FieldValue.serverTimestamp(),
              'failedOn': FieldValue.serverTimestamp(),
            });
            
            // Delete from current semester
            await semesterRef.collection('students').doc(studentId).delete();
            
            print("Moved student $studentId to repeat Semester $semester");
          }
          // Skip students with null isPassed (shouldn't happen with pre-validation)
        }
        
        // Update promotion status in semester document
        await semesterRef.set({
          'lastPromotionDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // Refresh data after promotion
      await _fetchSemesterData();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promotion completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error during promotion process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during promotion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Semester Promotion',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchSemesterData,
            tooltip: 'Refresh semester data',
          ),
        ],
      ),
      body: Container(
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
        child: _isVerified ? _buildPromotionContent() : _buildVerificationScreen(),
      ),
    );
  }
  
  Widget _buildVerificationScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Icon(
                      Icons.security,
                      size: 64,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Admin Verification Required',
                    style: GoogleFonts.raleway(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Semester promotion is a sensitive operation. Please verify your credentials to continue.',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: _showVerificationError ? 'Invalid credentials' : null,
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  
                  // Captcha verification
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _captchaText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                            letterSpacing: 8,
                            color: Colors.grey[800],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: _generateCaptcha,
                          tooltip: 'Generate new captcha',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _captchaController,
                    decoration: InputDecoration(
                      labelText: 'Enter captcha above',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _verifyAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('VERIFY & CONTINUE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromotionContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Loading semester data...',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_semesters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'No semester data available',
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchSemesterData,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // Check if any promotion can be done
    bool canPromoteAny = false;
    for (int semester in _semesters) {
      if (_semesterData[semester]!['canPromote']) {
        canPromoteAny = true;
        break;
      }
    }
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semester Promotion Management',
                style: GoogleFonts.raleway(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select semesters to promote students. All passed students will be moved to the next semester.',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Failed students will be moved to the repeat collection.',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              
              if (!canPromoteAny)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'No semesters can be promoted yet. Teachers need to mark all students as Pass or Fail first.',
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: _semesters.length,
                  itemBuilder: (context, index) {
                    final semester = _semesters[index];
                    final semesterInfo = _semesterData[semester]!;
                    final bool canPromote = semesterInfo['canPromote'];
                    
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _semesterSelectedForPromotion[semester]! 
                              ? Color(0xFF1B5E20)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            if (canPromote)
                              Checkbox(
                                value: _semesterSelectedForPromotion[semester],
                                onChanged: (value) {
                                  setState(() {
                                    _semesterSelectedForPromotion[semester] = value!;
                                  });
                                },
                                activeColor: Color(0xFF1B5E20),
                              ),
                            Expanded(
                              child: Text(
                                'Semester $semester',
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w600,
                                  color: canPromote ? Color(0xFF1B5E20) : Colors.grey[600],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: canPromote 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: canPromote ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                canPromote ? 'Ready' : 'Not Ready',
                                style: GoogleFonts.raleway(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: canPromote ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text(
                            'Total: ${semesterInfo['totalStudents']} students',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStudentStatusRow(
                                  'Passed Students',
                                  semesterInfo['passedStudents'],
                                  semesterInfo['totalStudents'],
                                  Colors.green,
                                ),
                                SizedBox(height: 8),
                                _buildStudentStatusRow(
                                  'Failed Students',
                                  semesterInfo['failedStudents'],
                                  semesterInfo['totalStudents'],
                                  Colors.red,
                                ),
                                SizedBox(height: 8),
                                _buildStudentStatusRow(
                                  'Not Marked Students',
                                  semesterInfo['notMarkedStudents'],
                                  semesterInfo['totalStudents'],
                                  Colors.amber,
                                ),
                                
                                if (semesterInfo['notMarkedStudents'] > 0)
                                  Container(
                                    margin: EdgeInsets.only(top: 16),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${semesterInfo['notMarkedStudents']} students need to be marked as Pass/Fail before promotion',
                                            style: GoogleFonts.raleway(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.amber[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                SizedBox(height: 16),
                                
                                if (semester < 8)
                                  Text(
                                    'Passed students will be promoted to Semester ${semester + 1}',
                                    style: GoogleFonts.raleway(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Text(
                                    'Passed students will be added to Alumni',
                                    style: GoogleFonts.raleway(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  
                                SizedBox(height: 8),
                                
                                Text(
                                  'Failed students will be moved to ${semesterInfo['repeatCollectionExists'] ? 'existing' : 'new'} Semester $semester-Repeat collection',
                                  style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                
                                SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.visibility),
                                      label: Text('View Results'),
                                      onPressed: () {
                                        // Navigate to UpdateResultsPage filtered for this semester
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UpdateResultsPage(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Color(0xFF1B5E20),
                                        side: BorderSide(color: Color(0xFF1B5E20)),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    if (canPromote)
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.arrow_forward),
                                        label: Text('Promote Semester $semester'),
                                        onPressed: () {
                                          setState(() {
                                            _semesterSelectedForPromotion[semester] = true;
                                          });
                                          _processPromotion();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF1B5E20),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom action button for bulk promotion
              if (canPromoteAny)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.publish),
                    label: Text('PROCESS SELECTED PROMOTIONS'),
                    onPressed: _processPromotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF1B5E20),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Processing Promotion',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait while students are being promoted...',
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
// Helper method to build student status rows
  Widget _buildStudentStatusRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count (${percentage.toStringAsFixed(1)}%)',
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class UpdateResultsPage extends StatefulWidget {
  final int? preSelectedSemester;
  
  const UpdateResultsPage({
    Key? key, 
    this.preSelectedSemester,
  }) : super(key: key);

  @override
  _UpdateResultsPageState createState() => _UpdateResultsPageState();
}

class _UpdateResultsPageState extends State<UpdateResultsPage> {
  int? _selectedSemester;
  bool _isLoading = false;
  List<Map<String, dynamic>> _studentsList = [];
  
  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.preSelectedSemester;
    if (_selectedSemester != null) {
      _fetchStudentsForSemester(_selectedSemester!);
    }
  }
  
  Future<void> _fetchStudentsForSemester(int semester) async {
    setState(() {
      _isLoading = true;
      _studentsList = [];
    });
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final studentsRef = firestore
          .collection('classes')
          .doc('Sem$semester')
          .collection('students');
          
      final studentsSnapshot = await studentsRef.get();
      
      List<Map<String, dynamic>> studentsList = [];
      
      for (var doc in studentsSnapshot.docs) {
        final studentData = doc.data();
        studentsList.add({
          'id': doc.id,
          'name': studentData['name'] ?? 'Unknown',
          'admissionNo': studentData['admissionNo'] ?? '',
          'isPassed': studentData['isPassed'],
          // Add other fields as needed
        });
      }
      
      // Sort by name
      studentsList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      
      setState(() {
        _studentsList = studentsList;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateStudentStatus(String studentId, bool isPassed) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc('Sem$_selectedSemester')
          .collection('students')
          .doc(studentId)
          .update({'isPassed': isPassed});
          
      // Update local list
      setState(() {
        final index = _studentsList.indexWhere((student) => student['id'] == studentId);
        if (index != -1) {
          _studentsList[index]['isPassed'] = isPassed;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student status updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error updating student status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating student status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Results',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
      ),
      body: Container(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Pass/Fail Status',
                style: GoogleFonts.raleway(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Mark students as passed or failed for promotion purposes.',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              
              // Semester selection dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF1B5E20)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedSemester,
                    hint: Text('Select Semester'),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
                    items: List.generate(8, (index) => index + 1).map((semester) {
                      return DropdownMenuItem<int>(
                        value: semester,
                        child: Text('Semester $semester'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                      if (value != null) {
                        _fetchStudentsForSemester(value);
                      }
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Students list
              if (_selectedSemester == null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Please select a semester to view students',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else if (_isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                )
              else if (_studentsList.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No students found in Semester $_selectedSemester',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _studentsList.length,
                    itemBuilder: (context, index) {
                      final student = _studentsList[index];
                      final bool? isPassed = student['isPassed'];
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
                            child: Text(
                              student['name'].substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student['name'],
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Admission No: ${student['admissionNo']}',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _updateStudentStatus(student['id'], true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPassed == true 
                                      ? Colors.green 
                                      : Colors.grey.shade200,
                                  foregroundColor: isPassed == true 
                                      ? Colors.white 
                                      : Colors.black,
                                  minimumSize: Size(60, 36),
                                ),
                                child: Text('Pass'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateStudentStatus(student['id'], false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPassed == false 
                                      ? Colors.red 
                                      : Colors.grey.shade200,
                                  foregroundColor: isPassed == false 
                                      ? Colors.white 
                                      : Colors.black,
                                  minimumSize: Size(60, 36),
                                ),
                                child: Text('Fail'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
              // Summary and action buttons
              if (_selectedSemester != null && !_isLoading && _studentsList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results Summary:',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusSummary(
                            'Passed',
                            _studentsList.where((s) => s['isPassed'] == true).length,
                            Colors.green,
                          ),
                          SizedBox(width: 24),
                          _buildStatusSummary(
                            'Failed',
                            _studentsList.where((s) => s['isPassed'] == false).length,
                            Colors.red,
                          ),
                          SizedBox(width: 24),
                          _buildStatusSummary(
                            'Not Marked',
                            _studentsList.where((s) => s['isPassed'] == null).length,
                            Colors.amber,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      if (_studentsList.any((s) => s['isPassed'] == null))
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Some students have not been marked as Pass/Fail yet. Please complete all evaluations.',
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusSummary(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$label: $count',
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}