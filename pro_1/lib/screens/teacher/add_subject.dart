// lib/screens/teacher/manage_teaching_subjects.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeachingSubjectsPage extends StatefulWidget {
  final String teacherId;

  const ManageTeachingSubjectsPage({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  _ManageTeachingSubjectsPageState createState() => _ManageTeachingSubjectsPageState();
}

class _ManageTeachingSubjectsPageState extends State<ManageTeachingSubjectsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedSemester = '1';
  bool _isLoading = false;
  
  // List to store subjects for the selected semester
  List<Map<String, dynamic>> _semesterSubjects = [];
  
  // List to store subjects taught by this teacher
  Set<String> _teachingSubjectIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadSubjectsForSemester();
  }
  
  // Load subjects for the selected semester
  Future<void> _loadSubjectsForSemester() async {
    setState(() {
      _isLoading = true;
      _semesterSubjects = [];
    });
    
    try {
      // Get subjects for the selected semester
      final subjectsSnapshot = await _firestore
          .collection('classes')
          .doc('Sem$_selectedSemester')
          .collection('subjects')
          .get();
      
      // Get the list of subject IDs that this teacher teaches
      await _loadTeachingSubjectIds();
      
      setState(() {
        _semesterSubjects = subjectsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final subjectId = doc.id;
              return {
                'id': subjectId,
                'name': data['name'] ?? '',
                'code': data['code'] ?? '',
                'displayName': '${data['code']} - ${data['name']}',
                'isTeaching': _teachingSubjectIds.contains(subjectId),
              };
            })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subjects: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Load the list of subject IDs that this teacher teaches
  Future<void> _loadTeachingSubjectIds() async {
    _teachingSubjectIds.clear();
    
    // Query all semesters to find subjects taught by this teacher
    final semesters = List.generate(8, (index) => 'Sem${index + 1}');
    
    for (String semester in semesters) {
      final subjectsSnapshot = await _firestore
          .collection('classes')
          .doc(semester)
          .collection('subjects')
          .where('teacherIds', arrayContains: widget.teacherId)
          .get();
      
      for (var doc in subjectsSnapshot.docs) {
        _teachingSubjectIds.add(doc.id);
      }
    }
  }
  
  // Toggle whether the teacher teaches a subject
  Future<void> _toggleTeachingSubject(String subjectId, bool currentValue) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final subjectRef = _firestore
          .collection('classes')
          .doc('Sem$_selectedSemester')
          .collection('subjects')
          .doc(subjectId);
      
      if (currentValue) {
        // Remove teacher from the subject
        await subjectRef.update({
          'teacherIds': FieldValue.arrayRemove([widget.teacherId]),
        });
        
        setState(() {
          _teachingSubjectIds.remove(subjectId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are no longer teaching this subject'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Add teacher to the subject
        await subjectRef.update({
          'teacherIds': FieldValue.arrayUnion([widget.teacherId]),
        });
        
        setState(() {
          _teachingSubjectIds.add(subjectId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subject added to your teaching list'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Update the UI
      _loadSubjectsForSemester();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating teaching subject: $e'),
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
          'My Teaching Subjects',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select which subjects you teach by semester',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Semester selection
                  Text(
                    'Select Semester',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSemester,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1B5E20)),
                        items: List.generate(8, (index) => (index + 1).toString())
                            .map((semester) {
                              return DropdownMenuItem(
                                value: semester,
                                child: Text(
                                  'Semester $semester',
                                  style: GoogleFonts.raleway(),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSemester = value;
                            });
                            _loadSubjectsForSemester();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Subjects list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _semesterSubjects.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No subjects found for Semester $_selectedSemester',
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _semesterSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = _semesterSubjects[index];
                            final isTeaching = _teachingSubjectIds.contains(subject['id']);
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isTeaching ? Color(0xFF1B5E20) : Colors.transparent,
                                  width: isTeaching ? 1 : 0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  subject['displayName'],
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Switch(
                                  value: isTeaching,
                                  activeColor: Color(0xFF1B5E20),
                                  onChanged: (bool value) {
                                    _toggleTeachingSubject(subject['id'], isTeaching);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}