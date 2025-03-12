import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class WeeklyAttendancePage extends StatefulWidget {
  @override
  _WeeklyAttendancePageState createState() => _WeeklyAttendancePageState();
}

class _WeeklyAttendancePageState extends State<WeeklyAttendancePage> {
  DateTime currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1)
  );
  
  final subjects = {
    'DS': 'Data Structures',
    'ALGO': 'Algorithm Design',
    'WEB': 'Web Development',
    'NET': 'Computer Networks',
    'OS': 'Operating Systems',
    'AI': 'Artificial Intelligence',
    'DB': 'Database Management',
    'SE': 'Software Engineering'
  };

  final schedule = {
    'Monday': ['DS', 'ALGO', 'WEB', 'NET', 'OS', 'AI'],
    'Tuesday': ['AI', 'DB', 'SE', 'DS', 'WEB', 'NET'],
    'Wednesday': ['OS', 'SE', 'DB', 'ALGO', 'AI', 'DS'],
    'Thursday': ['WEB', 'NET', 'OS', 'SE', 'DB', 'ALGO'],
    'Friday': ['DB', 'DS', 'AI', 'WEB', 'NET', 'OS'],
  };

  Map<String, Map<String, List<bool>>> sampleAttendance = {};

  @override
  void initState() {
    super.initState();
    DateTime fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));
    DateTime current = fourWeeksAgo;
    
    while (current.isBefore(DateTime.now())) {
      if (current.weekday <= 5) {
        String dateKey = DateFormat('yyyy-MM-dd').format(current);
        sampleAttendance[dateKey] = {
          'attendance': List.generate(6, (index) => Random().nextBool())
        };
      }
      current = current.add(Duration(days: 1));
    }
  }

  String _getTimeSlot(int periodIndex) {
    switch (periodIndex) {
      case 0: return '9:00 - 10:00';
      case 1: return '10:05 - 11:05';
      case 2: return '11:10 - 12:10';
      case 3: return '1:15 - 2:15';
      case 4: return '2:20 - 3:20';
      case 5: return '3:25 - 4:25';
      default: return '';
    }
  }

  Widget _buildAttendanceCell(String day, int periodIndex, bool? isPresent) {
    String subject = schedule[day]![periodIndex];
    String timeSlot = _getTimeSlot(periodIndex);
    
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isPresent == null 
          ? Colors.grey[200]
          : (isPresent ? Colors.green[100] : Colors.red[100]),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subject,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              timeSlot,
              style: GoogleFonts.raleway(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F5E9),  // Light green
                Colors.white,
                Color(0xFFE8F5E9),  // Light green
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Weekly Attendance',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
                      onPressed: () {
                        setState(() {
                          currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
                        });
                      },
                    ),
                    Text(
                      '${DateFormat('MMM d').format(currentWeekStart)} - '
                      '${DateFormat('MMM d').format(currentWeekStart.add(Duration(days: 4)))}',
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Color(0xFF1B5E20)),
                      onPressed: () {
                        if (currentWeekStart.isBefore(DateTime.now())) {
                          setState(() {
                            currentWeekStart = currentWeekStart.add(Duration(days: 7));
                          });
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
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(0.8),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Color(0xFF1B5E20).withOpacity(0.1),
                          ),
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Day',
                                  style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            ...List.generate(6, (index) {
                              return TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Period ${index + 1}',
                                    style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
                          return TableRow(
                            children: [
                              TableCell(
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    day.substring(0, 3),
                                    style: GoogleFonts.raleway(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              ...List.generate(6, (periodIndex) {
                                DateTime currentDate = currentWeekStart.add(
                                  Duration(days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].indexOf(day))
                                );
                                String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
                                bool? attendance = sampleAttendance[dateKey]?['attendance']?[periodIndex];
                                
                                return TableCell(
                                  child: SizedBox(
                                    height: 60,
                                    child: _buildAttendanceCell(day, periodIndex, attendance),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Present', Colors.green[100]!, Colors.green[800]!),
                    SizedBox(width: 16),
                    _buildLegendItem('Absent', Colors.red[100]!, Colors.red[800]!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color backgroundColor, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            label == 'Present' ? Icons.check : Icons.close,
            color: iconColor,
            size: 16,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}