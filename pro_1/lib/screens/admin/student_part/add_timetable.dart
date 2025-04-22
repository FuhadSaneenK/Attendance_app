import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableForm extends StatefulWidget {
  const TimetableForm({Key? key}) : super(key: key);

  @override
  _TimetableFormState createState() => _TimetableFormState();
}

class _TimetableFormState extends State<TimetableForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Selected semester
  String _selectedSemester = '1';
  
  // Time slots
  final List<String> _timeSlots = [
    '9:00 - 10:00',
    '10:05 - 11:05',
    '11:10 - 12:10',
    '1:15 - 2:15',
    '2:20 - 3:20',
    '3:25 - 4:25',
  ];
  
  // Days of the week
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  
  // Map to store subject names for each time slot and day
  Map<String, Map<String, String>> _timetableData = {};
  
  // Loading state
  bool _isLoading = false;
  
  // List to store subjects for the selected semester
  List<Map<String, dynamic>> _semesterSubjects = [];
  
  @override
  void initState() {
    super.initState();
    _initializeTimetableData();
    _loadSubjectsForSemester();
  }
  
  // Initialize empty timetable data
  void _initializeTimetableData() {
    for (String day in _days) {
      _timetableData[day] = {};
      for (String timeSlot in _timeSlots) {
        _timetableData[day]![timeSlot] = '';
      }
    }
  }
  
  // Load subjects for the selected semester
  Future<void> _loadSubjectsForSemester() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final subjectsSnapshot = await _firestore
          .collection('classes')
          .doc('Sem${_selectedSemester}')
          .collection('subjects')
          .get();
      
      setState(() {
        _semesterSubjects = subjectsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'],
                'code': data['code'],
                'displayName': '${data['code']} - ${data['name']}',
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
  
  // Save timetable to Firestore
  Future<void> _saveTimetable() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Create a reference to the timetable collection
        final timetableRef = _firestore.collection('timetable');
        
        // Save data under the semester document - using just the semester number
        await timetableRef.doc(_selectedSemester).set(_timetableData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving timetable: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load existing timetable data if available
  Future<void> _loadTimetable() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final timetableDoc = await _firestore
          .collection('timetable')
          .doc(_selectedSemester)
          .get();
      
      if (timetableDoc.exists) {
        final data = timetableDoc.data() as Map<String, dynamic>;
        
        setState(() {
          for (String day in _days) {
            if (data.containsKey(day)) {
              _timetableData[day] = Map<String, String>.from(data[day]);
            } else {
              // Initialize if day doesn't exist in loaded data
              _timetableData[day] = {};
              for (String timeSlot in _timeSlots) {
                _timetableData[day]![timeSlot] = '';
              }
            }
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable loaded successfully!')),
        );
      } else {
        _initializeTimetableData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No existing timetable found for Semester $_selectedSemester')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading timetable: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Timetable',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          // Semester Selection
          Text(
            'Select Semester:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSemester,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: List.generate(8, (index) => (index + 1).toString())
                .map((semester) => DropdownMenuItem<String>(
                      value: semester,
                      child: Text('Semester $semester'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSemester = value!;
                _loadSubjectsForSemester();
                _loadTimetable();
              });
            },
          ),
          SizedBox(height: 24),
          
          // Timetable Grid
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _semesterSubjects.isEmpty 
                ? Center(
                    child: Text(
                      'No subjects found for Semester $_selectedSemester. Please add subjects first.',
                      style: TextStyle(fontSize: 16),
                    )
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: [
                        DataColumn(label: Text('Time / Day')),
                        ..._days.map((day) => DataColumn(label: Text(day))),
                      ],
                      rows: _timeSlots.map((timeSlot) {
                        return DataRow(cells: [
                          DataCell(Text(timeSlot)),
                          ..._days.map((day) {
                            return DataCell(
                              DropdownButtonFormField<String>(
                                value: _timetableData[day]![timeSlot]!.isEmpty 
                                    ? null 
                                    : _timetableData[day]![timeSlot],
                                decoration: InputDecoration(
                                  hintText: 'Select subject',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                items: [
                                  // Empty option to allow clearing the slot
                                  DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('No Class'),
                                  ),
                                  // Subject options
                                  ..._semesterSubjects.map((subject) => 
                                    DropdownMenuItem<String>(
                                      value: subject['displayName'],
                                      child: Text(
                                        subject['displayName'], 
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _timetableData[day]![timeSlot] = value ?? '';
                                  });
                                },
                                isExpanded: true,
                              ),
                            );
                          }).toList(),
                        ]);
                      }).toList(),
                    ),
                  ),
          SizedBox(height: 24),
          
          // Save Button
          if (_semesterSubjects.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTimetable,
                  child: Text('Save Timetable'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class TimetableForm extends StatefulWidget {
//   const TimetableForm({Key? key}) : super(key: key);

//   @override
//   _TimetableFormState createState() => _TimetableFormState();
// }

// class _TimetableFormState extends State<TimetableForm> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Selected semester
//   String _selectedSemester = '1';
  
//   // Time slots
//   final List<String> _timeSlots = [
//     '9:00 - 10:00',
//     '10:05 - 11:05',
//     '11:10 - 12:10',
//     '1:15 - 2:15',
//     '2:20 - 3:20',
//     '3:25 - 4:25',
//   ];
  
//   // Days of the week
//   final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  
//   // Map to store subject names for each time slot and day
//   Map<String, Map<String, String>> _timetableData = {};
  
//   // Loading state
//   bool _isLoading = false;
  
//   // List to store subjects for the selected semester
//   List<Map<String, dynamic>> _semesterSubjects = [];
  
//   @override
//   void initState() {
//     super.initState();
//     _initializeTimetableData();
//     _loadSubjectsForSemester();
//   }
  
//   // Initialize empty timetable data
//   void _initializeTimetableData() {
//     for (String day in _days) {
//       _timetableData[day] = {};
//       for (String timeSlot in _timeSlots) {
//         _timetableData[day]![timeSlot] = '';
//       }
//     }
//   }
  
//   // Load subjects for the selected semester
//   Future<void> _loadSubjectsForSemester() async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final subjectsSnapshot = await _firestore
//           .collection('classes')
//           .doc('Sem$_selectedSemester')
//           .collection('subjects')
//           .get();
      
//       setState(() {
//         _semesterSubjects = subjectsSnapshot.docs
//             .map((doc) {
//               final data = doc.data();
//               return {
//                 'id': doc.id,
//                 'name': data['name'],
//                 'code': data['code'],
//                 'displayName': '${data['code']} - ${data['name']}',
//               };
//             })
//             .toList();
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading subjects: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
  
//   // Save timetable to Firestore
//   Future<void> _saveTimetable() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       try {
//         // Create a reference to the timetable collection
//         final timetableRef = _firestore.collection('timetable');
        
//         // Save data under the semester document
//         await timetableRef.doc('Sem$_selectedSemester').set(_timetableData);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Timetable saved successfully!')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving timetable: $e')),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
  
//   // Load existing timetable data if available
//   Future<void> _loadTimetable() async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final timetableDoc = await _firestore
//           .collection('timetable')
//           .doc('Sem$_selectedSemester')
//           .get();
      
//       if (timetableDoc.exists) {
//         final data = timetableDoc.data() as Map<String, dynamic>;
        
//         setState(() {
//           for (String day in _days) {
//             if (data.containsKey(day)) {
//               _timetableData[day] = Map<String, String>.from(data[day]);
//             } else {
//               // Initialize if day doesn't exist in loaded data
//               _timetableData[day] = {};
//               for (String timeSlot in _timeSlots) {
//                 _timetableData[day]![timeSlot] = '';
//               }
//             }
//           }
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Timetable loaded successfully!')),
//         );
//       } else {
//         _initializeTimetableData();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('No existing timetable found for Semester $_selectedSemester')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading timetable: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Add Timetable',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 24),
          
//           // Semester Selection
//           Text(
//             'Select Semester:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value: _selectedSemester,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(),
//               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             items: List.generate(8, (index) => (index + 1).toString())
//                 .map((semester) => DropdownMenuItem<String>(
//                       value: semester,
//                       child: Text('Semester $semester'),
//                     ))
//                 .toList(),
//             onChanged: (value) {
//               setState(() {
//                 _selectedSemester = value!;
//                 _loadSubjectsForSemester();
//                 _loadTimetable();
//               });
//             },
//           ),
//           SizedBox(height: 24),
          
//           // Timetable Grid
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : _semesterSubjects.isEmpty 
//                 ? Center(
//                     child: Text(
//                       'No subjects found for Semester $_selectedSemester. Please add subjects first.',
//                       style: TextStyle(fontSize: 16),
//                     )
//                   )
//                 : SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 20,
//                       border: TableBorder.all(color: Colors.grey.shade300),
//                       columns: [
//                         DataColumn(label: Text('Time / Day')),
//                         ..._days.map((day) => DataColumn(label: Text(day))),
//                       ],
//                       rows: _timeSlots.map((timeSlot) {
//                         return DataRow(cells: [
//                           DataCell(Text(timeSlot)),
//                           ..._days.map((day) {
//                             return DataCell(
//                               DropdownButtonFormField<String>(
//                                 value: _timetableData[day]![timeSlot]!.isEmpty 
//                                     ? null 
//                                     : _timetableData[day]![timeSlot],
//                                 decoration: InputDecoration(
//                                   hintText: 'Select subject',
//                                   border: InputBorder.none,
//                                   contentPadding: EdgeInsets.symmetric(horizontal: 8),
//                                 ),
//                                 items: [
//                                   // Empty option to allow clearing the slot
//                                   DropdownMenuItem<String>(
//                                     value: '',
//                                     child: Text('No Class'),
//                                   ),
//                                   // Subject options
//                                   ..._semesterSubjects.map((subject) => 
//                                     DropdownMenuItem<String>(
//                                       value: subject['displayName'],
//                                       child: Text(
//                                         subject['displayName'], 
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     )
//                                   ).toList(),
//                                 ],
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _timetableData[day]![timeSlot] = value ?? '';
//                                   });
//                                 },
//                                 isExpanded: true,
//                               ),
//                             );
//                           }).toList(),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//           SizedBox(height: 24),
          
//           // Save Button
//           if (_semesterSubjects.isNotEmpty)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _saveTimetable,
//                   child: Text('Save Timetable'),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }
