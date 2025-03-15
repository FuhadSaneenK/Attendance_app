import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';

class MarkAttendancePage extends StatefulWidget {
  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  String selectedClass = 'Class 10A';
  String selectedSubject = 'Mathematics';
  String selectedPeriod = '9:00 - 10:00'; // Default first period
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isSubmitting = false;
  
  // New variables for theory/practical and batches
  String selectedType = 'Theory'; // Default to Theory
  List<String> selectedBatches = [];
  List<String> selectedPeriods = [];
  bool isMultiPeriod = false;

  // Sample subject list
  final subjects = [
    'Mathematics',
    'Science', 
    'English',
    'History',
    'Computer Science',
    'Physical Education'
  ];
  
  // Period timings
  final periods = [
    '9:00 - 10:00',
    '10:05 - 11:05',
    '11:10 - 12:10',
    '1:15 - 2:15',
    '2:20 - 3:20',
    '3:25 - 4:25',
  ];
  
  // Batch options
  final batches = ['Batch A', 'Batch B', 'Batch C', 'Batch D'];
  
  // Student data from Firebase
  List<Map<String, dynamic>> students = [];
  List<String> classes = [];

  // Define color scheme
  final Color primaryColor = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadStudents();
    // Initialize with first period selected
    selectedPeriods = [selectedPeriod];
  }

  Future<void> _loadClasses() async {
    final classList = await AttendanceService.getAllClasses();
    if (classList.isNotEmpty) {
      setState(() {
        classes = classList;
        selectedClass = classList[0];
      });
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    try {
      final classId = selectedClass;
      
      // Modify to include batch filtering if practical is selected
      final studentList = await AttendanceService.getStudentsForClass(
        classId, 
        batches: selectedType == 'Practical' ? selectedBatches : null
      );
      
      setState(() {
        students = studentList;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading students: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => isSubmitting = true);
    try {
      final classId = selectedClass;
      
      // For practical with multiple periods, submit for each period
      bool allSuccess = true;
      for (String period in selectedPeriods) {
        final result = await AttendanceService.submitAttendance(
          classId: classId,
          subject: selectedSubject,
          period: period,
          date: selectedDate,
          studentsAttendance: students,
          isTheory: selectedType == 'Theory',
          batches: selectedType == 'Practical' ? selectedBatches : null,
        );
        if (!result) {
          allSuccess = false;
          break;
        }
      }
      
      if (allSuccess) {
        _showSuccessSnackBar('Attendance submitted successfully');
      } else {
        _showErrorSnackBar('Failed to submit attendance for some periods');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleBatch(String batch) {
    setState(() {
      if (selectedBatches.contains(batch)) {
        selectedBatches.remove(batch);
      } else {
        selectedBatches.add(batch);
      }
      _loadStudents();
    });
  }

  void _togglePeriod(String period) {
    setState(() {
      if (selectedPeriods.contains(period)) {
        selectedPeriods.remove(period);
      } else {
        selectedPeriods.add(period);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Mark Attendance',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(selectedDate),
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      _loadStudents();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class, Subject and Period Selection
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDropdown(
                                  'Semester',
                                  selectedClass,
                                  classes.isEmpty ? ['Class 10A', 'Class 10B'] : classes,
                                  (value) {
                                    setState(() => selectedClass = value!);
                                    _loadStudents();
                                  },
                                ),
                                SizedBox(height: 16),
                                _buildDropdown(
                                  'Subject',
                                  selectedSubject,
                                  subjects,
                                  (value) {
                                    setState(() => selectedSubject = value!);
                                    _loadStudents();
                                  },
                                ),
                                SizedBox(height: 16),
                                
                                // New: Theory/Practical Selection
                                _buildDropdown(
                                  'Type',
                                  selectedType,
                                  ['Theory', 'Practical'],
                                  (value) {
                                    setState(() {
                                      selectedType = value!;
                                      // Reset batches when changing type
                                      if (value == 'Theory') {
                                        selectedBatches = [];
                                        isMultiPeriod = false;
                                        selectedPeriods = [selectedPeriod];
                                      }
                                    });
                                    _loadStudents();
                                  },
                                ),
                                
                                // Show batch selection only if practical is selected
                                if (selectedType == 'Practical') ...[
                                  SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Batches',
                                        style: GoogleFonts.raleway(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: batches.map((batch) {
                                          final isSelected = selectedBatches.contains(batch);
                                          return FilterChip(
                                            label: Text(batch),
                                            selected: isSelected,
                                            onSelected: (selected) => _toggleBatch(batch),
                                            selectedColor: primaryColor.withOpacity(0.2),
                                            checkmarkColor: primaryColor,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isMultiPeriod,
                                        onChanged: (value) {
                                          setState(() {
                                            isMultiPeriod = value!;
                                            if (!isMultiPeriod) {
                                              selectedPeriods = [selectedPeriod];
                                            }
                                          });
                                        },
                                        activeColor: primaryColor,
                                      ),
                                      Text(
                                        'Select Multiple Periods',
                                        style: GoogleFonts.raleway(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                
                                SizedBox(height: 16),
                                if (!isMultiPeriod) 
                                  _buildDropdown(
                                    'Period',
                                    selectedPeriod,
                                    periods,
                                    (value) {
                                      setState(() {
                                        selectedPeriod = value!;
                                        selectedPeriods = [selectedPeriod];
                                      });
                                      _loadStudents();
                                    },
                                  )
                                else 
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Periods',
                                        style: GoogleFonts.raleway(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: periods.map((period) {
                                          final isSelected = selectedPeriods.contains(period);
                                          return FilterChip(
                                            label: Text(period),
                                            selected: isSelected,
                                            onSelected: (selected) => _togglePeriod(period),
                                            selectedColor: primaryColor.withOpacity(0.2),
                                            checkmarkColor: primaryColor,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Time Slot Info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: primaryColor),
                                  SizedBox(width: 12),
                                  Text(
                                    'Session Details',
                                    style: GoogleFonts.raleway(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Type: $selectedType',
                                style: GoogleFonts.raleway(fontSize: 14),
                              ),
                              if (selectedType == 'Practical' && selectedBatches.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  'Batches: ${selectedBatches.join(", ")}',
                                  style: GoogleFonts.raleway(fontSize: 14),
                                ),
                              ],
                              SizedBox(height: 4),
                              Text(
                                'Periods: ${selectedPeriods.join(", ")}',
                                style: GoogleFonts.raleway(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Attendance Table
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (selectedType == 'Practical' && selectedBatches.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Please select at least one batch for practical session',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else if (isMultiPeriod && selectedPeriods.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Please select at least one period',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else if (students.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No students found for this selection',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(1.5),
                                      2: FlexColumnWidth(1),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                        ),
                                        children: [
                                          _buildTableHeader('Student Name'),
                                          _buildTableHeader('ID'),
                                          _buildTableHeader('Status'),
                                        ],
                                      ),
                                      ...students.map((student) => TableRow(
                                        children: [
                                          _buildTableCell(student['name']),
                                          _buildTableCell(student['id']),
                                          TableCell(
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Switch(
                                                value: student['isPresent'],
                                                onChanged: (value) {
                                                  setState(() => student['isPresent'] = value);
                                                },
                                                activeColor: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )).toList(),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
          // Submit Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (isSubmitting || 
                        (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                        (isMultiPeriod && selectedPeriods.isEmpty)) 
                      ? null 
                      : _submitAttendance,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                             (isMultiPeriod && selectedPeriods.isEmpty)
                          ? Colors.grey
                          : primaryColor
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                                   (isMultiPeriod && selectedPeriods.isEmpty)
                                ? Colors.grey
                                : primaryColor,
                          ),
                      SizedBox(width: 12),
                      Text(
                        isSubmitting ? 'Submitting...' : 'Submit Attendance',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                                 (isMultiPeriod && selectedPeriods.isEmpty)
                              ? Colors.grey
                              : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return TableCell(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          text,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return TableCell(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          text,
          style: GoogleFonts.raleway(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.raleway()),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}












// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:intl/intl.dart';

// // class MarkAttendancePage extends StatefulWidget {
// //   @override
// //   _MarkAttendancePageState createState() => _MarkAttendancePageState();
// // }

// // class _MarkAttendancePageState extends State<MarkAttendancePage> {
// //   String selectedClass = 'Class 10A';
// //   String selectedSubject = 'Mathematics';
// //   String selectedPeriod = '9:00 - 10:00'; // Default first period
// //   DateTime selectedDate = DateTime.now();

// //   // Sample subject list
// //   final subjects = [
// //     'Mathematics',
// //     'Science', 
// //     'English',
// //     'History',
// //     'Computer Science',
// //     'Physical Education'
// //   ];
  
// //   // Period timings
// //   final periods = [
// //     '9:00 - 10:00',
// //     '10:05 - 11:05',
// //     '11:10 - 12:10',
// //     '1:15 - 2:15',
// //     '2:20 - 3:20',
// //     '3:25 - 4:25',
// //   ];
  
// //   // Sample student data
// //   final List<Map<String, dynamic>> students = [
// //     {'name': 'Alice Smith', 'id': '2024001', 'isPresent': true},
// //     {'name': 'Bob Johnson', 'id': '2024002', 'isPresent': true},
// //     {'name': 'Carol White', 'id': '2024003', 'isPresent': true},
// //     {'name': 'David Brown', 'id': '2024004', 'isPresent': true},
// //     {'name': 'Eva Davis', 'id': '2024005', 'isPresent': true},
// //   ];

// //   // Define color scheme
// //   final Color primaryColor = Color(0xFF1B5E20);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: primaryColor,
// //         title: Text(
// //           'Mark Attendance',
// //           style: GoogleFonts.playfairDisplay(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         leading: IconButton(
// //           icon: Icon(Icons.arrow_back, color: Colors.white),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //       ),
// //       body: Column(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(16),
// //             color: primaryColor.withOpacity(0.1),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   DateFormat('EEEE, MMMM d').format(selectedDate),
// //                   style: GoogleFonts.raleway(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 IconButton(
// //                   icon: Icon(Icons.calendar_today),
// //                   onPressed: () async {
// //                     final DateTime? picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: selectedDate,
// //                       firstDate: DateTime(2024),
// //                       lastDate: DateTime.now(),
// //                     );
// //                     if (picked != null) {
// //                       setState(() => selectedDate = picked);
// //                     }
// //                   },
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: SingleChildScrollView(
// //               child: Padding(
// //                 padding: EdgeInsets.all(16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // Class, Subject and Period Selection
// //                     Card(
// //                       elevation: 0,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                         side: BorderSide(color: Colors.grey.shade200),
// //                       ),
// //                       child: Padding(
// //                         padding: EdgeInsets.all(16),
// //                         child: Column(
// //                           children: [
// //                             _buildDropdown(
// //                               'Class',
// //                               selectedClass,
// //                               ['Class 10A', 'Class 10B', 'Class 11A', 'Class 11B'],
// //                               (value) => setState(() => selectedClass = value!),
// //                             ),
// //                             SizedBox(height: 16),
// //                             _buildDropdown(
// //                               'Subject',
// //                               selectedSubject,
// //                               subjects,
// //                               (value) => setState(() => selectedSubject = value!),
// //                             ),
// //                             SizedBox(height: 16),
// //                             _buildDropdown(
// //                               'Period',
// //                               selectedPeriod,
// //                               periods,
// //                               (value) => setState(() => selectedPeriod = value!),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(height: 20),
                    
// //                     // Time Slot Info
// //                     Container(
// //                       padding: EdgeInsets.all(16),
// //                       decoration: BoxDecoration(
// //                         color: primaryColor.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(Icons.access_time, color: primaryColor),
// //                           SizedBox(width: 12),
// //                           Text(
// //                             'Period: $selectedPeriod',
// //                             style: GoogleFonts.raleway(
// //                               fontSize: 16,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     SizedBox(height: 20),
                    
// //                     // Attendance Table
// //                     Card(
// //                       elevation: 0,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                         side: BorderSide(color: Colors.grey.shade200),
// //                       ),
// //                       child: Padding(
// //                         padding: EdgeInsets.all(16),
// //                         child: Column(
// //                           children: [
// //                             Table(
// //                               columnWidths: const {
// //                                 0: FlexColumnWidth(2),
// //                                 1: FlexColumnWidth(1.5),
// //                                 2: FlexColumnWidth(1),
// //                               },
// //                               children: [
// //                                 TableRow(
// //                                   decoration: BoxDecoration(
// //                                     color: primaryColor.withOpacity(0.1),
// //                                   ),
// //                                   children: [
// //                                     _buildTableHeader('Student Name'),
// //                                     _buildTableHeader('ID'),
// //                                     _buildTableHeader('Status'),
// //                                   ],
// //                                 ),
// //                                 ...students.map((student) => TableRow(
// //                                   children: [
// //                                     _buildTableCell(student['name']),
// //                                     _buildTableCell(student['id']),
// //                                     TableCell(
// //                                       child: Padding(
// //                                         padding: EdgeInsets.all(8),
// //                                         child: Switch(
// //                                           value: student['isPresent'],
// //                                           onChanged: (value) {
// //                                             setState(() => student['isPresent'] = value);
// //                                           },
// //                                           activeColor: primaryColor,
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 )).toList(),
// //                               ],
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //           // Submit Button with outline style similar to profile page
// //           Container(
// //             padding: EdgeInsets.all(16),
// //             decoration: BoxDecoration(
// //               color: Colors.white,
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.05),
// //                   blurRadius: 10,
// //                   offset: Offset(0, -4),
// //                 ),
// //               ],
// //             ),
// //             child: Material(
// //               color: Colors.transparent,
// //               child: InkWell(
// //                 onTap: () {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Attendance submitted successfully')),
// //                   );
// //                 },
// //                 child: Container(
// //                   width: double.infinity,
// //                   padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: primaryColor),
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Icon(
// //                         Icons.check_circle_outline,
// //                         size: 20,
// //                         color: primaryColor,
// //                       ),
// //                       SizedBox(width: 12),
// //                       Text(
// //                         'Submit Attendance',
// //                         style: GoogleFonts.raleway(
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600,
// //                           color: primaryColor,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTableHeader(String text) {
// //     return TableCell(
// //       child: Padding(
// //         padding: EdgeInsets.all(12),
// //         child: Text(
// //           text,
// //           style: GoogleFonts.raleway(
// //             fontWeight: FontWeight.bold,
// //             fontSize: 14,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTableCell(String text) {
// //     return TableCell(
// //       child: Padding(
// //         padding: EdgeInsets.all(12),
// //         child: Text(
// //           text,
// //           style: GoogleFonts.raleway(fontSize: 14),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildDropdown(
// //     String label,
// //     String value,
// //     List<String> items,
// //     void Function(String?) onChanged,
// //   ) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           label,
// //           style: GoogleFonts.raleway(
// //             fontSize: 14,
// //             fontWeight: FontWeight.w500,
// //             color: Colors.grey[600],
// //           ),
// //         ),
// //         SizedBox(height: 8),
// //         Container(
// //           decoration: BoxDecoration(
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(color: Colors.grey.shade200),
// //           ),
// //           child: DropdownButtonHideUnderline(
// //             child: DropdownButton<String>(
// //               value: value,
// //               isExpanded: true,
// //               padding: EdgeInsets.symmetric(horizontal: 16),
// //               borderRadius: BorderRadius.circular(12),
// //               items: items.map((String item) {
// //                 return DropdownMenuItem<String>(
// //                   value: item,
// //                   child: Text(item, style: GoogleFonts.raleway()),
// //                 );
// //               }).toList(),
// //               onChanged: onChanged,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }













// //-----------------------------------------------------------------------------------------------




// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:pro_1/services/attendance_service.dart';


// class MarkAttendancePage extends StatefulWidget {
//   @override
//   _MarkAttendancePageState createState() => _MarkAttendancePageState();
// }

// class _MarkAttendancePageState extends State<MarkAttendancePage> {
//   String selectedClass = 'Class 10A';
//   String selectedSubject = 'Mathematics';
//   String selectedPeriod = '9:00 - 10:00'; // Default first period
//   DateTime selectedDate = DateTime.now();
//   bool isLoading = false;
//   bool isSubmitting = false;

//   // Sample subject list
//   final subjects = [
//     'Mathematics',
//     'Science', 
//     'English',
//     'History',
//     'Computer Science',
//     'Physical Education'
//   ];
  
//   // Period timings
//   final periods = [
//     '9:00 - 10:00',
//     '10:05 - 11:05',
//     '11:10 - 12:10',
//     '1:15 - 2:15',
//     '2:20 - 3:20',
//     '3:25 - 4:25',
//   ];
  
//   // Student data from Firebase
//   List<Map<String, dynamic>> students = [];
//   List<String> classes = [];

//   // Define color scheme
//   final Color primaryColor = Color(0xFF1B5E20);

//   @override
//   void initState() {
//     super.initState();
//     _loadClasses();
//     _loadStudents();
//   }


//   Future<void> _loadClasses() async {
//   final classList = await AttendanceService.getAllClasses();
//   if (classList.isNotEmpty) {
//     setState(() {
//       classes = classList;
//       selectedClass = classList[0];
//     });
//     _loadStudents();
//   }
// }



//   Future<void> _loadStudents() async {
//     setState(() => isLoading = true);
//     try {
//       final classId = selectedClass;
//       final studentList = await AttendanceService.getStudentsForClass(classId);
//       setState(() {
//         students = studentList;
//       });
//     } catch (e) {
//       _showErrorSnackBar('Error loading students: $e');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _submitAttendance() async {
//   setState(() => isSubmitting = true);
//   try {
//     final classId = selectedClass;
//     final result = await AttendanceService.submitAttendance(
//       classId: classId,
//       subject: selectedSubject,
//       period: selectedPeriod,
//       date: selectedDate,
//       studentsAttendance: students,
//     );
//     if (result) _showSuccessSnackBar('Attendance submitted successfully');
//   } catch (e) {
//     _showErrorSnackBar('Error: $e');
//   } finally {
//     setState(() => isSubmitting = false);
//   }
// }


//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         title: Text(
//           'Mark Attendance',
//           style: GoogleFonts.playfairDisplay(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(16),
//             color: primaryColor.withOpacity(0.1),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   DateFormat('EEEE, MMMM d').format(selectedDate),
//                   style: GoogleFonts.raleway(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.calendar_today),
//                   onPressed: () async {
//                     final DateTime? picked = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime(2024),
//                       lastDate: DateTime.now(),
//                     );
//                     if (picked != null) {
//                       setState(() => selectedDate = picked);
//                       _loadStudents(); // Reload students with attendance data for new date
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: isLoading 
//               ? Center(child: CircularProgressIndicator(color: primaryColor))
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Class, Subject and Period Selection
//                         Card(
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(color: Colors.grey.shade200),
//                           ),
//                           child: Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               children: [
//                                 _buildDropdown(
//                                   'Class',
//                                   selectedClass,
//                                   classes.isEmpty ? ['Class 10A', 'Class 10B'] : classes,
//                                   (value) {
//                                     setState(() => selectedClass = value!);
//                                     _loadStudents();
//                                   },
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildDropdown(
//                                   'Subject',
//                                   selectedSubject,
//                                   subjects,
//                                   (value) {
//                                     setState(() => selectedSubject = value!);
//                                     _loadStudents();
//                                   },
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildDropdown(
//                                   'Period',
//                                   selectedPeriod,
//                                   periods,
//                                   (value) {
//                                     setState(() => selectedPeriod = value!);
//                                     _loadStudents();
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
                        
//                         // Time Slot Info
//                         Container(
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: primaryColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(Icons.access_time, color: primaryColor),
//                               SizedBox(width: 12),
//                               Text(
//                                 'Period: $selectedPeriod',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: 20),
                        
//                         // Attendance Table
//                         Card(
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(color: Colors.grey.shade200),
//                           ),
//                           child: Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               children: [
//                                 students.isEmpty
//                                   ? Padding(
//                                       padding: EdgeInsets.all(16),
//                                       child: Text(
//                                         'No students found for this class',
//                                         style: GoogleFonts.raleway(),
//                                       ),
//                                     )
//                                   : Table(
//                                       columnWidths: const {
//                                         0: FlexColumnWidth(2),
//                                         1: FlexColumnWidth(1.5),
//                                         2: FlexColumnWidth(1),
//                                       },
//                                       children: [
//                                         TableRow(
//                                           decoration: BoxDecoration(
//                                             color: primaryColor.withOpacity(0.1),
//                                           ),
//                                           children: [
//                                             _buildTableHeader('Student Name'),
//                                             _buildTableHeader('ID'),
//                                             _buildTableHeader('Status'),
//                                           ],
//                                         ),
//                                         ...students.map((student) => TableRow(
//                                           children: [
//                                             _buildTableCell(student['name']),
//                                             _buildTableCell(student['id']),
//                                             TableCell(
//                                               child: Padding(
//                                                 padding: EdgeInsets.all(8),
//                                                 child: Switch(
//                                                   value: student['isPresent'],
//                                                   onChanged: (value) {
//                                                     setState(() => student['isPresent'] = value);
//                                                   },
//                                                   activeColor: primaryColor,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         )).toList(),
//                                       ],
//                                     ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//           ),
//           // Submit Button
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: Offset(0, -4),
//                 ),
//               ],
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: isSubmitting ? null : _submitAttendance,
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: primaryColor),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       isSubmitting
//                         ? SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: primaryColor,
//                             ),
//                           )
//                         : Icon(
//                             Icons.check_circle_outline,
//                             size: 20,
//                             color: primaryColor,
//                           ),
//                       SizedBox(width: 12),
//                       Text(
//                         isSubmitting ? 'Submitting...' : 'Submit Attendance',
//                         style: GoogleFonts.raleway(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTableHeader(String text) {
//     return TableCell(
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Text(
//           text,
//           style: GoogleFonts.raleway(
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTableCell(String text) {
//     return TableCell(
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Text(
//           text,
//           style: GoogleFonts.raleway(fontSize: 14),
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(
//     String label,
//     String value,
//     List<String> items,
//     void Function(String?) onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.raleway(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[600],
//           ),
//         ),
//         SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: value,
//               isExpanded: true,
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               borderRadius: BorderRadius.circular(12),
//               items: items.map((String item) {
//                 return DropdownMenuItem<String>(
//                   value: item,
//                   child: Text(item, style: GoogleFonts.raleway()),
//                 );
//               }).toList(),
//               onChanged: onChanged,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }








