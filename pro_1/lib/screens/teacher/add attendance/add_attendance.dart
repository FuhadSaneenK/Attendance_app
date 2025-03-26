import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';

class MarkAttendancePage extends StatefulWidget {
  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  String selectedClass = 'Class 10A';
  String selectedSubject = '';
  String selectedPeriod = '';
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isSubmitting = false;
  bool isLoadingSubjects = false;
  bool isLoadingPeriods = false;
  
  // Variables for theory/practical and batches
  String selectedType = 'Theory'; // Default to Theory
  List<String> selectedBatches = [];
  List<String> selectedPeriods = [];
  bool isMultiPeriod = false;
  
  // Holiday data
  List<DateTime> holidays = [];
  bool isLoadingHolidays = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Subject list from Firebase
  List<String> subjects = [];
  
  // Available periods for selected subject
  List<String> availablePeriods = [];
  
  // All periods
  final allPeriods = [
    '9:00 - 10:00',
    '10:05 - 11:05',
    '11:10 - 12:10',
    '1:15 - 2:15',
    '2:20 - 3:20',
    '3:25 - 4:25',
  ];
  
  // Day of the week
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  
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
    _loadHolidays();
    _loadClasses();
  }

  // Load holidays from Firebase
  Future<void> _loadHolidays() async {
    setState(() => isLoadingHolidays = true);
    try {
      // Get holidays from Firestore
      final holidaysList = await AttendanceService.getHolidays();
      setState(() {
        holidays = holidaysList;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading holidays: $e');
    } finally {
      setState(() => isLoadingHolidays = false);
    }
  }

  Future<void> _loadClasses() async {
    final classList = await AttendanceService.getAllClasses();
    if (classList.isNotEmpty) {
      setState(() {
        classes = classList;
        selectedClass = classList[0];
      });
      _loadSubjectsForSemester(selectedClass);
    }
  }

  Future<void> _loadSubjectsForSemester(String semester) async {
    setState(() => isLoadingSubjects = true);
    try {
      // Extract semester number from the class name
      String semesterNumber = semester.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Get current day of week
      String currentDay = DateFormat('EEEE').format(selectedDate);
      if (!days.contains(currentDay)) {
        currentDay = 'Monday'; // Default to Monday if weekend
      }

      // Fetch the timetable for the selected semester
      final timetableDoc = await _firestore
          .collection('timetable')
          .doc(semesterNumber)
          .get();

      if (timetableDoc.exists) {
        final data = timetableDoc.data() as Map<String, dynamic>;
        
        // Extract all subjects from timetable for the current day
        Set<String> subjectsSet = {};
        
        if (data.containsKey(currentDay)) {
          final dayData = data[currentDay] as Map<String, dynamic>;
          
          // Add all non-empty subjects to the set
          dayData.forEach((timeSlot, subject) {
            if (subject != null && subject.toString().isNotEmpty) {
              subjectsSet.add(subject.toString());
            }
          });
        }
        
        // Convert set to list to remove duplicates
        List<String> subjectsList = subjectsSet.toList();
        
        // Sort alphabetically
        subjectsList.sort();
        
        setState(() {
          subjects = subjectsList;
          selectedSubject = ''; // Reset subject selection
          selectedPeriod = ''; // Reset period selection
          selectedPeriods = []; // Reset multi-period selection
          availablePeriods = []; // Reset available periods
        });
      } else {
        setState(() {
          subjects = [];
          selectedSubject = '';
          selectedPeriod = '';
          selectedPeriods = [];
          availablePeriods = [];
        });
        _showErrorSnackBar('No timetable found for this semester');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading subjects: $e');
      setState(() {
        subjects = [];
        selectedSubject = '';
        selectedPeriod = '';
        selectedPeriods = [];
        availablePeriods = [];
      });
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  Future<void> _loadPeriodsForSubject(String subject) async {
    if (subject.isEmpty) return;
    
    setState(() => isLoadingPeriods = true);
    try {
      // Extract semester number from the class name
      String semesterNumber = selectedClass.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Get current day of week
      String currentDay = DateFormat('EEEE').format(selectedDate);
      if (!days.contains(currentDay)) {
        currentDay = 'Monday'; // Default to Monday if weekend
      }

      // Fetch the timetable for the selected semester
      final timetableDoc = await _firestore
          .collection('timetable')
          .doc(semesterNumber)
          .get();

      if (timetableDoc.exists) {
        final data = timetableDoc.data() as Map<String, dynamic>;
        List<String> periodsList = [];
        
        if (data.containsKey(currentDay)) {
          final dayData = data[currentDay] as Map<String, dynamic>;
          
          // Find periods that match the selected subject
          dayData.forEach((timeSlot, subjectName) {
            if (subjectName == subject) {
              periodsList.add(timeSlot);
            }
          });
        }
        
        setState(() {
          availablePeriods = periodsList;
          // Reset period selection if current selection is not valid
          if (periodsList.isNotEmpty) {
            if (!periodsList.contains(selectedPeriod)) {
              selectedPeriod = periodsList[0];
              selectedPeriods = [selectedPeriod];
            }
          } else {
            selectedPeriod = '';
            selectedPeriods = [];
          }
        });
        
        // Load students after periods are set
        _loadStudents();
      } else {
        setState(() {
          availablePeriods = [];
          selectedPeriod = '';
          selectedPeriods = [];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading periods: $e');
      setState(() {
        availablePeriods = [];
        selectedPeriod = '';
        selectedPeriods = [];
      });
    } finally {
      setState(() => isLoadingPeriods = false);
    }
  }

  Future<void> _loadStudents() async {
    // Check if we have sufficient selections to load students
    if (selectedSubject.isEmpty || 
        (availablePeriods.isEmpty) || 
        (selectedPeriods.isEmpty)) {
      setState(() => students = []);
      return;
    }
    
    // For practical sessions, check if batches are selected
    if (selectedType == 'Practical' && selectedBatches.isEmpty) {
      setState(() => students = []);
      return;
    }
    
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
    // Validate subject selection
    if (selectedSubject.isEmpty) {
      _showErrorSnackBar('Please select a subject');
      return;
    }
    
    // Validate period selection
    if (selectedPeriods.isEmpty) {
      _showErrorSnackBar('No periods available for this subject');
      return;
    }
    
    // Validate batch selection for practical sessions
    if (selectedType == 'Practical' && selectedBatches.isEmpty) {
      _showErrorSnackBar('Please select at least one batch for practical session');
      return;
    }
    
    setState(() => isSubmitting = true);
    try {
      final classId = selectedClass;
      
      // For multiple periods, submit for each period
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

  // Check if a date is a holiday
  bool _isHoliday(DateTime date) {
    final dayName = DateFormat('EEEE').format(date);
    
    // Check if it's weekend
    if (dayName == 'Saturday' || dayName == 'Sunday') {
      return true;
    }
    
    // Check if it's in the holidays list
    for (var holiday in holidays) {
      if (DateFormat('yyyy-MM-dd').format(holiday) == 
          DateFormat('yyyy-MM-dd').format(date)) {
        return true;
      }
    }
    
    return false;
  }

  // Custom date selection method with holiday restrictions
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime date) {
        // Allow selection only if not a holiday
        return !_isHoliday(date);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      // Reload subjects when date changes since it affects day of week
      _loadSubjectsForSemester(selectedClass);
    }
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
                  onPressed: isLoadingHolidays 
                      ? null 
                      : () => _selectDate(context),
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
                                    _loadSubjectsForSemester(value!);
                                  },
                                ),
                                SizedBox(height: 16),
                                
                                // Subject dropdown with loading indicator
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subject',
                                      style: GoogleFonts.raleway(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    isLoadingSubjects 
                                      ? Center(
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                        )
                                      : subjects.isEmpty
                                        ? Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Text(
                                              'No subjects available for this semester',
                                              style: GoogleFonts.raleway(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedSubject.isEmpty ? null : selectedSubject,
                                                hint: Text('Select Subject'),
                                                isExpanded: true,
                                                padding: EdgeInsets.symmetric(horizontal: 16),
                                                borderRadius: BorderRadius.circular(12),
                                                items: subjects.map((String item) {
                                                  return DropdownMenuItem<String>(
                                                    value: item,
                                                    child: Text(item, style: GoogleFonts.raleway()),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() => selectedSubject = value!);
                                                  // Load corresponding periods
                                                  _loadPeriodsForSubject(value!);
                                                },
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                                
                                SizedBox(height: 16),
                                
                                // Theory/Practical Selection
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
                                      } else {
                                        // Reset selected periods for practical
                                        selectedPeriods = [];
                                      }
                                    });
                                    _loadStudents();
                                  },
                                ),
                                
                                SizedBox(height: 16),
                                
                                // Multiple Period Selection Checkbox (for both Theory and Practical)
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isMultiPeriod,
                                      onChanged: (value) {
                                        setState(() {
                                          isMultiPeriod = value!;
                                          if (!isMultiPeriod && availablePeriods.isNotEmpty) {
                                            selectedPeriod = availablePeriods[0];
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
                                ],
                                
                                SizedBox(height: 16),
                                
                                // Period selection with loading indicator
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMultiPeriod ? 'Select Periods' : 'Period',
                                      style: GoogleFonts.raleway(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    isLoadingPeriods 
                                      ? Center(
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                        )
                                      : availablePeriods.isEmpty
                                        ? Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Text(
                                              selectedSubject.isEmpty 
                                                ? 'Please select a subject first'
                                                : 'No periods found for this subject',
                                              style: GoogleFonts.raleway(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                        : !isMultiPeriod
                                          ? Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: selectedPeriod.isEmpty ? null : selectedPeriod,
                                                  hint: Text('Select Period'),
                                                  isExpanded: true,
                                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                                  borderRadius: BorderRadius.circular(12),
                                                  items: availablePeriods.map((String item) {
                                                    return DropdownMenuItem<String>(
                                                      value: item,
                                                      child: Text(item, style: GoogleFonts.raleway()),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedPeriod = value!;
                                                      selectedPeriods = [selectedPeriod];
                                                    });
                                                    _loadStudents();
                                                  },
                                                ),
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: availablePeriods.map((period) {
                                                final isSelected = selectedPeriods.contains(period);
                                                return FilterChip(
                                                  label: Text(period),
                                                  selected: isSelected,
                                                  onSelected: (selected) {
                                                    _togglePeriod(period);
                                                    // Trigger student loading after period selection changes
                                                    _loadStudents();
                                                  },
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
                                'Periods: ${selectedPeriods.isEmpty ? "None selected" : selectedPeriods.join(", ")}',
                                style: GoogleFonts.raleway(fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Subject: ${selectedSubject.isEmpty ? "Not selected" : selectedSubject}',
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
                                if (selectedSubject.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Please select a subject to mark attendance',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else if (availablePeriods.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No periods available for this subject in the timetable',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else if (selectedType == 'Practical' && selectedBatches.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Please select at least one batch for practical session',
                                      style: GoogleFonts.raleway(),
                                    ),
                                  )
                                else if (selectedPeriods.isEmpty)
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
                                        )),
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
                        selectedSubject.isEmpty ||
                        availablePeriods.isEmpty ||
                        (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                        selectedPeriods.isEmpty) 
                      ? null 
                      : _submitAttendance,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (selectedSubject.isEmpty ||
                             availablePeriods.isEmpty ||
                             (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                             selectedPeriods.isEmpty)
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
                            color: (selectedSubject.isEmpty ||
                                   availablePeriods.isEmpty ||
                                   (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                                   selectedPeriods.isEmpty)
                                ? Colors.grey
                                : primaryColor,
                          ),
                      SizedBox(width: 12),
                      Text(
                        isSubmitting ? 'Submitting...' : 'Submit Attendance',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: (selectedSubject.isEmpty || availablePeriods.isEmpty ||
                                 (selectedType == 'Practical' && selectedBatches.isEmpty) ||
                                 selectedPeriods.isEmpty)
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
              value: value.isEmpty && items.isNotEmpty ? null : value,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              hint: Text('Select ${label}'),
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









// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';

// class MarkAttendancePage extends StatefulWidget {
//   @override
//   _MarkAttendancePageState createState() => _MarkAttendancePageState();
// }

// class _MarkAttendancePageState extends State<MarkAttendancePage> {
//   String selectedClass = 'Class 10A';
//   String selectedSubject = '';
//   String selectedPeriod = '';
//   DateTime selectedDate = DateTime.now();
//   bool isLoading = false;
//   bool isSubmitting = false;
//   bool isLoadingSubjects = false;
//   bool isLoadingPeriods = false;
  
//   // Variables for theory/practical and batches
//   String selectedType = 'Theory'; // Default to Theory
//   List<String> selectedBatches = [];
//   List<String> selectedPeriods = [];
//   bool isMultiPeriod = false;

//   // Firestore instance
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Subject list from Firebase
//   List<String> subjects = [];
  
//   // Available periods for selected subject
//   List<String> availablePeriods = [];
  
//   // All periods
//   final allPeriods = [
//     '9:00 - 10:00',
//     '10:05 - 11:05',
//     '11:10 - 12:10',
//     '1:15 - 2:15',
//     '2:20 - 3:20',
//     '3:25 - 4:25',
//   ];
  
//   // Day of the week
//   final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  
//   // Batch options
//   final batches = ['Batch A', 'Batch B', 'Batch C', 'Batch D'];
  
//   // Student data from Firebase
//   List<Map<String, dynamic>> students = [];
//   List<String> classes = [];

//   // Define color scheme
//   final Color primaryColor = Color(0xFF1B5E20);

//   @override
//   void initState() {
//     super.initState();
//     _loadClasses();
//   }

//   Future<void> _loadClasses() async {
//     final classList = await AttendanceService.getAllClasses();
//     if (classList.isNotEmpty) {
//       setState(() {
//         classes = classList;
//         selectedClass = classList[0];
//       });
//       _loadSubjectsForSemester(selectedClass);
//     }
//   }

//   Future<void> _loadSubjectsForSemester(String semester) async {
//     setState(() => isLoadingSubjects = true);
//     try {
//       // Extract semester number from the class name
//       String semesterNumber = semester.replaceAll(RegExp(r'[^0-9]'), '');
      
//       // Get current day of week
//       String currentDay = DateFormat('EEEE').format(selectedDate);
//       if (!days.contains(currentDay)) {
//         currentDay = 'Monday'; // Default to Monday if weekend
//       }

//       // Fetch the timetable for the selected semester
//       final timetableDoc = await _firestore
//           .collection('timetable')
//           .doc(semesterNumber)
//           .get();

//       if (timetableDoc.exists) {
//         final data = timetableDoc.data() as Map<String, dynamic>;
        
//         // Extract all subjects from timetable for the current day
//         Set<String> subjectsSet = {};
        
//         if (data.containsKey(currentDay)) {
//           final dayData = data[currentDay] as Map<String, dynamic>;
          
//           // Add all non-empty subjects to the set
//           dayData.forEach((timeSlot, subject) {
//             if (subject != null && subject.toString().isNotEmpty) {
//               subjectsSet.add(subject.toString());
//             }
//           });
//         }
        
//         // Convert set to list to remove duplicates
//         List<String> subjectsList = subjectsSet.toList();
        
//         // Sort alphabetically
//         subjectsList.sort();
        
//         setState(() {
//           subjects = subjectsList;
//           selectedSubject = ''; // Reset subject selection
//           selectedPeriod = ''; // Reset period selection
//           selectedPeriods = []; // Reset multi-period selection
//           availablePeriods = []; // Reset available periods
//         });
//       } else {
//         setState(() {
//           subjects = [];
//           selectedSubject = '';
//           selectedPeriod = '';
//           selectedPeriods = [];
//           availablePeriods = [];
//         });
//         _showErrorSnackBar('No timetable found for this semester');
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error loading subjects: $e');
//       setState(() {
//         subjects = [];
//         selectedSubject = '';
//         selectedPeriod = '';
//         selectedPeriods = [];
//         availablePeriods = [];
//       });
//     } finally {
//       setState(() => isLoadingSubjects = false);
//     }
//   }

//   Future<void> _loadPeriodsForSubject(String subject) async {
//     if (subject.isEmpty) return;
    
//     setState(() => isLoadingPeriods = true);
//     try {
//       // Extract semester number from the class name
//       String semesterNumber = selectedClass.replaceAll(RegExp(r'[^0-9]'), '');
      
//       // Get current day of week
//       String currentDay = DateFormat('EEEE').format(selectedDate);
//       if (!days.contains(currentDay)) {
//         currentDay = 'Monday'; // Default to Monday if weekend
//       }

//       // Fetch the timetable for the selected semester
//       final timetableDoc = await _firestore
//           .collection('timetable')
//           .doc(semesterNumber)
//           .get();

//       if (timetableDoc.exists) {
//         final data = timetableDoc.data() as Map<String, dynamic>;
//         List<String> periodsList = [];
        
//         if (data.containsKey(currentDay)) {
//           final dayData = data[currentDay] as Map<String, dynamic>;
          
//           // Find periods that match the selected subject
//           dayData.forEach((timeSlot, subjectName) {
//             if (subjectName == subject) {
//               periodsList.add(timeSlot);
//             }
//           });
//         }
        
//         setState(() {
//           availablePeriods = periodsList;
//           // Reset period selection if current selection is not valid
//           if (periodsList.isNotEmpty) {
//             if (!periodsList.contains(selectedPeriod)) {
//               selectedPeriod = periodsList[0];
//               selectedPeriods = [selectedPeriod];
//             }
//           } else {
//             selectedPeriod = '';
//             selectedPeriods = [];
//           }
//         });
        
//         // Load students after periods are set
//         _loadStudents();
//       } else {
//         setState(() {
//           availablePeriods = [];
//           selectedPeriod = '';
//           selectedPeriods = [];
//         });
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error loading periods: $e');
//       setState(() {
//         availablePeriods = [];
//         selectedPeriod = '';
//         selectedPeriods = [];
//       });
//     } finally {
//       setState(() => isLoadingPeriods = false);
//     }
//   }

//   Future<void> _loadStudents() async {
//     // Check if we have sufficient selections to load students
//     if (selectedSubject.isEmpty || 
//         (availablePeriods.isEmpty) || 
//         (selectedPeriods.isEmpty)) {
//       setState(() => students = []);
//       return;
//     }
    
//     // For practical sessions, check if batches are selected
//     if (selectedType == 'Practical' && selectedBatches.isEmpty) {
//       setState(() => students = []);
//       return;
//     }
    
//     setState(() => isLoading = true);
//     try {
//       final classId = selectedClass;
      
//       // Modify to include batch filtering if practical is selected
//       final studentList = await AttendanceService.getStudentsForClass(
//         classId, 
//         batches: selectedType == 'Practical' ? selectedBatches : null
//       );
      
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
//     // Validate subject selection
//     if (selectedSubject.isEmpty) {
//       _showErrorSnackBar('Please select a subject');
//       return;
//     }
    
//     // Validate period selection
//     if (selectedPeriods.isEmpty) {
//       _showErrorSnackBar('No periods available for this subject');
//       return;
//     }
    
//     // Validate batch selection for practical sessions
//     if (selectedType == 'Practical' && selectedBatches.isEmpty) {
//       _showErrorSnackBar('Please select at least one batch for practical session');
//       return;
//     }
    
//     setState(() => isSubmitting = true);
//     try {
//       final classId = selectedClass;
      
//       // For multiple periods, submit for each period
//       bool allSuccess = true;
//       for (String period in selectedPeriods) {
//         final result = await AttendanceService.submitAttendance(
//           classId: classId,
//           subject: selectedSubject,
//           period: period,
//           date: selectedDate,
//           studentsAttendance: students,
//           isTheory: selectedType == 'Theory',
//           batches: selectedType == 'Practical' ? selectedBatches : null,
//         );
//         if (!result) {
//           allSuccess = false;
//           break;
//         }
//       }
      
//       if (allSuccess) {
//         _showSuccessSnackBar('Attendance submitted successfully');
//       } else {
//         _showErrorSnackBar('Failed to submit attendance for some periods');
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error: $e');
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }

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

//   void _toggleBatch(String batch) {
//     setState(() {
//       if (selectedBatches.contains(batch)) {
//         selectedBatches.remove(batch);
//       } else {
//         selectedBatches.add(batch);
//       }
//       _loadStudents();
//     });
//   }

//   void _togglePeriod(String period) {
//     setState(() {
//       if (selectedPeriods.contains(period)) {
//         selectedPeriods.remove(period);
//       } else {
//         selectedPeriods.add(period);
//       }
//     });
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
//                       // Reload subjects when date changes since it affects day of week
//                       _loadSubjectsForSemester(selectedClass);
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
//                                   'Semester',
//                                   selectedClass,
//                                   classes.isEmpty ? ['Class 10A', 'Class 10B'] : classes,
//                                   (value) {
//                                     setState(() => selectedClass = value!);
//                                     _loadSubjectsForSemester(value!);
//                                   },
//                                 ),
//                                 SizedBox(height: 16),
                                
//                                 // Subject dropdown with loading indicator
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Subject',
//                                       style: GoogleFonts.raleway(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                     SizedBox(height: 8),
//                                     isLoadingSubjects 
//                                       ? Center(
//                                           child: SizedBox(
//                                             height: 20,
//                                             width: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: primaryColor,
//                                             ),
//                                           ),
//                                         )
//                                       : subjects.isEmpty
//                                         ? Container(
//                                             width: double.infinity,
//                                             padding: EdgeInsets.all(12),
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.circular(12),
//                                               border: Border.all(color: Colors.grey.shade200),
//                                             ),
//                                             child: Text(
//                                               'No subjects available for this semester',
//                                               style: GoogleFonts.raleway(
//                                                 color: Colors.grey[600],
//                                               ),
//                                             ),
//                                           )
//                                         : Container(
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.circular(12),
//                                               border: Border.all(color: Colors.grey.shade200),
//                                             ),
//                                             child: DropdownButtonHideUnderline(
//                                               child: DropdownButton<String>(
//                                                 value: selectedSubject.isEmpty ? null : selectedSubject,
//                                                 hint: Text('Select Subject'),
//                                                 isExpanded: true,
//                                                 padding: EdgeInsets.symmetric(horizontal: 16),
//                                                 borderRadius: BorderRadius.circular(12),
//                                                 items: subjects.map((String item) {
//                                                   return DropdownMenuItem<String>(
//                                                     value: item,
//                                                     child: Text(item, style: GoogleFonts.raleway()),
//                                                   );
//                                                 }).toList(),
//                                                 onChanged: (value) {
//                                                   setState(() => selectedSubject = value!);
//                                                   // Load corresponding periods
//                                                   _loadPeriodsForSubject(value!);
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                   ],
//                                 ),
                                
//                                 SizedBox(height: 16),
                                
//                                 // Theory/Practical Selection
//                                 _buildDropdown(
//                                   'Type',
//                                   selectedType,
//                                   ['Theory', 'Practical'],
//                                   (value) {
//                                     setState(() {
//                                       selectedType = value!;
//                                       // Reset batches when changing type
//                                       if (value == 'Theory') {
//                                         selectedBatches = [];
//                                       } else {
//                                         // Reset selected periods for practical
//                                         selectedPeriods = [];
//                                       }
//                                     });
//                                     _loadStudents();
//                                   },
//                                 ),
                                
//                                 SizedBox(height: 16),
                                
//                                 // Multiple Period Selection Checkbox (for both Theory and Practical)
//                                 Row(
//                                   children: [
//                                     Checkbox(
//                                       value: isMultiPeriod,
//                                       onChanged: (value) {
//                                         setState(() {
//                                           isMultiPeriod = value!;
//                                           if (!isMultiPeriod && availablePeriods.isNotEmpty) {
//                                             selectedPeriod = availablePeriods[0];
//                                             selectedPeriods = [selectedPeriod];
//                                           }
//                                         });
//                                       },
//                                       activeColor: primaryColor,
//                                     ),
//                                     Text(
//                                       'Select Multiple Periods',
//                                       style: GoogleFonts.raleway(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
                                
//                                 // Show batch selection only if practical is selected
//                                 if (selectedType == 'Practical') ...[
//                                   SizedBox(height: 16),
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Select Batches',
//                                         style: GoogleFonts.raleway(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w500,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Wrap(
//                                         spacing: 8,
//                                         runSpacing: 8,
//                                         children: batches.map((batch) {
//                                           final isSelected = selectedBatches.contains(batch);
//                                           return FilterChip(
//                                             label: Text(batch),
//                                             selected: isSelected,
//                                             onSelected: (selected) => _toggleBatch(batch),
//                                             selectedColor: primaryColor.withOpacity(0.2),
//                                             checkmarkColor: primaryColor,
//                                           );
//                                         }).toList(),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
                                
//                                 SizedBox(height: 16),
                                
//                                 // Period selection with loading indicator
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       isMultiPeriod ? 'Select Periods' : 'Period',
//                                       style: GoogleFonts.raleway(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                     SizedBox(height: 8),
//                                     isLoadingPeriods 
//                                       ? Center(
//                                           child: SizedBox(
//                                             height: 20,
//                                             width: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: primaryColor,
//                                             ),
//                                           ),
//                                         )
//                                       : availablePeriods.isEmpty
//                                         ? Container(
//                                             width: double.infinity,
//                                             padding: EdgeInsets.all(12),
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.circular(12),
//                                               border: Border.all(color: Colors.grey.shade200),
//                                             ),
//                                             child: Text(
//                                               selectedSubject.isEmpty 
//                                                 ? 'Please select a subject first'
//                                                 : 'No periods found for this subject',
//                                               style: GoogleFonts.raleway(
//                                                 color: Colors.grey[600],
//                                               ),
//                                             ),
//                                           )
//                                         : !isMultiPeriod
//                                           ? Container(
//                                               decoration: BoxDecoration(
//                                                 borderRadius: BorderRadius.circular(12),
//                                                 border: Border.all(color: Colors.grey.shade200),
//                                               ),
//                                               child: DropdownButtonHideUnderline(
//                                                 child: DropdownButton<String>(
//                                                   value: selectedPeriod.isEmpty ? null : selectedPeriod,
//                                                   hint: Text('Select Period'),
//                                                   isExpanded: true,
//                                                   padding: EdgeInsets.symmetric(horizontal: 16),
//                                                   borderRadius: BorderRadius.circular(12),
//                                                   items: availablePeriods.map((String item) {
//                                                     return DropdownMenuItem<String>(
//                                                       value: item,
//                                                       child: Text(item, style: GoogleFonts.raleway()),
//                                                     );
//                                                   }).toList(),
//                                                   onChanged: (value) {
//                                                     setState(() {
//                                                       selectedPeriod = value!;
//                                                       selectedPeriods = [selectedPeriod];
//                                                     });
//                                                     _loadStudents();
//                                                   },
//                                                 ),
//                                               ),
//                                             )
//                                           : Wrap(
//                                               spacing: 8,
//                                               runSpacing: 8,
//                                               children: availablePeriods.map((period) {
//                                                 final isSelected = selectedPeriods.contains(period);
//                                                 return FilterChip(
//                                                   label: Text(period),
//                                                   selected: isSelected,
//                                                   onSelected: (selected) {
//                                                     _togglePeriod(period);
//                                                     // Trigger student loading after period selection changes
//                                                     _loadStudents();
//                                                   },
//                                                   selectedColor: primaryColor.withOpacity(0.2),
//                                                   checkmarkColor: primaryColor,
//                                                 );
//                                               }).toList(),
//                                             ),
//                                   ],
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
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.info_outline, color: primaryColor),
//                                   SizedBox(width: 12),
//                                   Text(
//                                     'Session Details',
//                                     style: GoogleFonts.raleway(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 8),
//                               Text(
//                                 'Type: $selectedType',
//                                 style: GoogleFonts.raleway(fontSize: 14),
//                               ),
//                               if (selectedType == 'Practical' && selectedBatches.isNotEmpty) ...[
//                                 SizedBox(height: 4),
//                                 Text(
//                                   'Batches: ${selectedBatches.join(", ")}',
//                                   style: GoogleFonts.raleway(fontSize: 14),
//                                 ),
//                               ],
//                               SizedBox(height: 4),
//                               Text(
//                                 'Periods: ${selectedPeriods.isEmpty ? "None selected" : selectedPeriods.join(", ")}',
//                                 style: GoogleFonts.raleway(fontSize: 14),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Subject: ${selectedSubject.isEmpty ? "Not selected" : selectedSubject}',
//                                 style: GoogleFonts.raleway(fontSize: 14),
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
//                                 if (selectedSubject.isEmpty)
//                                   Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: Text(
//                                       'Please select a subject to mark attendance',
//                                       style: GoogleFonts.raleway(),
//                                     ),
//                                   )
//                                 else if (availablePeriods.isEmpty)
//                                   Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: Text(
//                                       'No periods available for this subject in the timetable',
//                                       style: GoogleFonts.raleway(),
//                                     ),
//                                   )
//                                 else if (selectedType == 'Practical' && selectedBatches.isEmpty)
//                                   Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: Text(
//                                       'Please select at least one batch for practical session',
//                                       style: GoogleFonts.raleway(),
//                                     ),
//                                   )
//                                 else if (selectedPeriods.isEmpty)
//                                   Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: Text(
//                                       'Please select at least one period',
//                                       style: GoogleFonts.raleway(),
//                                     ),
//                                   )
//                                 else if (students.isEmpty)
//                                   Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: Text(
//                                       'No students found for this selection',
//                                       style: GoogleFonts.raleway(),
//                                     ),
//                                   )
//                                 else
//                                   Table(
//                                     columnWidths: const {
//                                       0: FlexColumnWidth(2),
//                                       1: FlexColumnWidth(1.5),
//                                       2: FlexColumnWidth(1),
//                                     },
//                                     children: [
//                                       TableRow(
//                                         decoration: BoxDecoration(
//                                           color: primaryColor.withOpacity(0.1),
//                                         ),
//                                         children: [
//                                           _buildTableHeader('Student Name'),
//                                           _buildTableHeader('ID'),
//                                           _buildTableHeader('Status'),
//                                         ],
//                                       ),
//                                       ...students.map((student) => TableRow(
//                                         children: [
//                                           _buildTableCell(student['name']),
//                                           _buildTableCell(student['id']),
//                                           TableCell(
//                                             child: Padding(
//                                               padding: EdgeInsets.all(8),
//                                               child: Switch(
//                                                 value: student['isPresent'],
//                                                 onChanged: (value) {
//                                                   setState(() => student['isPresent'] = value);
//                                                 },
//                                                 activeColor: primaryColor,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       )).toList(),
//                                     ],
//                                   ),
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
//                 onTap: (isSubmitting || 
//                         selectedSubject.isEmpty ||
//                         availablePeriods.isEmpty ||
//                         (selectedType == 'Practical' && selectedBatches.isEmpty) ||
//                         selectedPeriods.isEmpty) 
//                       ? null 
//                       : _submitAttendance,
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: (selectedSubject.isEmpty ||
//                              availablePeriods.isEmpty ||
//                              (selectedType == 'Practical' && selectedBatches.isEmpty) ||
//                              selectedPeriods.isEmpty)
//                           ? Colors.grey
//                           : primaryColor
//                     ),
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
//                             color: (selectedSubject.isEmpty ||
//                                    availablePeriods.isEmpty ||
//                                    (selectedType == 'Practical' && selectedBatches.isEmpty) ||
//                                    selectedPeriods.isEmpty)
//                                 ? Colors.grey
//                                 : primaryColor,
//                           ),
//                       SizedBox(width: 12),
//                       Text(
//                         isSubmitting ? 'Submitting...' : 'Submit Attendance',
//                         style: GoogleFonts.raleway(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: (selectedSubject.isEmpty || availablePeriods.isEmpty ||
//                                  (selectedType == 'Practical' && selectedBatches.isEmpty) ||
//                                  selectedPeriods.isEmpty)
//                               ? Colors.grey
//                               : primaryColor,
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
//               value: value.isEmpty && items.isNotEmpty ? null : value,
//               isExpanded: true,
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               borderRadius: BorderRadius.circular(12),
//               hint: Text('Select ${label}'),
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

