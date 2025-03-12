import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetablePage extends StatefulWidget {
  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int _selectedDay = DateTime.now().weekday - 1;
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  // Sample timetable data - replace with your actual data structure
  final Map<int, List<Map<String, String>>> _timetableData = {
    0: [ // Monday
      {
        'subject': 'Mathematics',
        'time': '09:00 - 10:30',
        'room': 'Room 101',
        'teacher': 'Dr. Smith'
      },
      {
        'subject': 'Physics',
        'time': '11:00 - 12:30',
        'room': 'Lab 203',
        'teacher': 'Prof. Johnson'
      },
            {
        'subject': 'Data Structure',
        'time': '1:00 - 2:30',
        'room': 'Lab 203',
        'teacher': 'Prof. ABC'
      },
    ],
    1: [ // Tuesday
      {
        'subject': 'Chemistry',
        'time': '09:00 - 10:30',
        'room': 'Lab 105',
        'teacher': 'Dr. Brown'
      },
    ],
    // Add data for other days
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(),
              
              // Day selector
              _buildDaySelector(),
              
              // Timetable content
              Expanded(
                child: _buildTimetableContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Class Timetable',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
            onPressed: () {
              // Add calendar view functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDay == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = index;
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF1B5E20) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekDays[index],
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimetableContent() {
    final classes = _timetableData[_selectedDay] ?? [];
    
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classInfo = classes[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Color(0xFF1B5E20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      classInfo['time']!,
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classInfo['subject']!,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.person_outline, classInfo['teacher']!),
                    SizedBox(height: 4),
                    _buildInfoRow(Icons.room, classInfo['room']!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}