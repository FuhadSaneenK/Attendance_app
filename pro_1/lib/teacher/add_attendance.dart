import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MarkAttendancePage extends StatefulWidget {
  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  String selectedClass = 'Class 10A';
  String selectedSubject = 'Mathematics';
  String selectedPeriod = '9:00 - 10:00'; // Default first period
  DateTime selectedDate = DateTime.now();

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
  
  // Sample student data
  final List<Map<String, dynamic>> students = [
    {'name': 'Alice Smith', 'id': '2024001', 'isPresent': true},
    {'name': 'Bob Johnson', 'id': '2024002', 'isPresent': true},
    {'name': 'Carol White', 'id': '2024003', 'isPresent': true},
    {'name': 'David Brown', 'id': '2024004', 'isPresent': true},
    {'name': 'Eva Davis', 'id': '2024005', 'isPresent': true},
  ];

  // Define color scheme
  final Color primaryColor = Color(0xFF1B5E20);

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
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
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
                              'Class',
                              selectedClass,
                              ['Class 10A', 'Class 10B', 'Class 11A', 'Class 11B'],
                              (value) => setState(() => selectedClass = value!),
                            ),
                            SizedBox(height: 16),
                            _buildDropdown(
                              'Subject',
                              selectedSubject,
                              subjects,
                              (value) => setState(() => selectedSubject = value!),
                            ),
                            SizedBox(height: 16),
                            _buildDropdown(
                              'Period',
                              selectedPeriod,
                              periods,
                              (value) => setState(() => selectedPeriod = value!),
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
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: primaryColor),
                          SizedBox(width: 12),
                          Text(
                            'Period: $selectedPeriod',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
          // Submit Button with outline style similar to profile page
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Attendance submitted successfully')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: primaryColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Submit Attendance',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
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