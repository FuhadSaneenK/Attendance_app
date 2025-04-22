import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSemesterSubjects extends StatefulWidget {
  @override
  _ManageSemesterSubjectsState createState() => _ManageSemesterSubjectsState();
}

class _ManageSemesterSubjectsState extends State<ManageSemesterSubjects> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  
  String _selectedSemester = '1';
  String _selectedDepartment = 'Computer Science'; // Keep this for the query
  bool _isLoading = false;
  
  // Sample list for dropdown menus
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get a reference to the specific semester in the classes collection
      DocumentReference semesterRef = FirebaseFirestore.instance
          .collection('classes')
          .doc('Sem${_selectedSemester}');
      
      // Check if the semester document exists, if not create it
      DocumentSnapshot semesterDoc = await semesterRef.get();
      if (!semesterDoc.exists) {
        await semesterRef.set({
          'semesterNumber': _selectedSemester,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Add the subject to the subjects subcollection
      await semesterRef.collection('subjects').add({
        'name': _subjectNameController.text.trim(),
        'code': _subjectCodeController.text.trim(),
        'department': _selectedDepartment,
        'teacherIds': [], // Empty list initially, teachers will be assigned later
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form after successful submission
      _subjectNameController.clear();
      _subjectCodeController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding subject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Semester Subjects',
          style: GoogleFonts.playfairDisplay(
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Subject',
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Semester Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedSemester,
                        items: _semesters.map((String semester) {
                          return DropdownMenuItem<String>(
                            value: semester,
                            child: Text('Semester $semester'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSemester = newValue;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Subject Code
                      TextFormField(
                        controller: _subjectCodeController,
                        decoration: InputDecoration(
                          labelText: 'Subject Code',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subject code';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Subject Name
                      TextFormField(
                        controller: _subjectNameController,
                        decoration: InputDecoration(
                          labelText: 'Subject Name',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subject name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addSubject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5E20),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Add Subject'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Display existing subjects
                Text(
                  'Existing Subjects',
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 16),
                
                // Modified query to avoid needing a composite index
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc('Sem${_selectedSemester}')
                      .collection('subjects')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No subjects found for this semester.',
                              style: GoogleFonts.raleway(),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Filter and sort the data client-side
                    var docs = snapshot.data!.docs;
                    docs = docs
                        .where((doc) => (doc.data() as Map<String, dynamic>)['department'] == _selectedDepartment)
                        .toList();
                    
                    // Sort by createdAt if available
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      
                      final aTime = aData['createdAt'] as Timestamp?;
                      final bTime = bData['createdAt'] as Timestamp?;
                      
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      
                      return bTime.compareTo(aTime); // Descending order
                    });
                    
                    if (docs.isEmpty) {
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No subjects found for this department.',
                              style: GoogleFonts.raleway(),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final subject = docs[index];
                        final data = subject.data() as Map<String, dynamic>;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              '${data['code']} - ${data['name']}',
                              style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Confirm deletion
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Subject'),
                                    content: Text('Are you sure you want to delete this subject?'),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: Text('Delete'),
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('classes')
                                      .doc('Sem${_selectedSemester}')
                                      .collection('subjects')
                                      .doc(subject.id)
                                      .delete();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Subject deleted successfully'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}