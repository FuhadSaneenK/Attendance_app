import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageTimetablePage extends StatefulWidget {
  @override
  _ManageTimetablePageState createState() => _ManageTimetablePageState();
}

class _ManageTimetablePageState extends State<ManageTimetablePage> {
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
    ],
    1: [ // Tuesday
      {
        'subject': 'Chemistry',
        'time': '09:00 - 10:30',
        'room': 'Lab 105',
        'teacher': 'Dr. Brown'
      },
    ],
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
              _buildAppBar(),
              _buildDaySelector(),
              Expanded(
                child: _buildTimetableContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1B5E20),
        child: Icon(Icons.add),
        onPressed: () => _showAddClassDialog(context),
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
              'Manage Timetable',
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
        return Dismissible(
          key: Key(classInfo['time']! + classInfo['subject']!),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              _timetableData[_selectedDay]?.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Class removed'),
                backgroundColor: Color(0xFF1B5E20),
              ),
            );
          },
          child: GestureDetector(
            onTap: () => _showEditClassDialog(context, index, classInfo),
            child: Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                        IconButton(
                          icon: Icon(Icons.edit, color: Color(0xFF1B5E20)),
                          onPressed: () => _showEditClassDialog(context, index, classInfo),
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
            ),
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

  void _showAddClassDialog(BuildContext context) {
    final _subjectController = TextEditingController();
    final _timeController = TextEditingController();
    final _roomController = TextEditingController();
    final _teacherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Class',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time (e.g., 09:00 - 10:30)',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _teacherController,
                decoration: InputDecoration(
                  labelText: 'Teacher',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Add',
              style: TextStyle(color: Color(0xFF1B5E20)),
            ),
            onPressed: () {
              if (_subjectController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty &&
                  _roomController.text.isNotEmpty &&
                  _teacherController.text.isNotEmpty) {
                setState(() {
                  if (_timetableData[_selectedDay] == null) {
                    _timetableData[_selectedDay] = [];
                  }
                  _timetableData[_selectedDay]!.add({
                    'subject': _subjectController.text,
                    'time': _timeController.text,
                    'room': _roomController.text,
                    'teacher': _teacherController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, int index, Map<String, String> classInfo) {
    final _subjectController = TextEditingController(text: classInfo['subject']);
    final _timeController = TextEditingController(text: classInfo['time']);
    final _roomController = TextEditingController(text: classInfo['room']);
    final _teacherController = TextEditingController(text: classInfo['teacher']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Class',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
              TextField(
                controller: _teacherController,
                decoration: InputDecoration(
                  labelText: 'Teacher',
                  labelStyle: TextStyle(color: Color(0xFF1B5E20)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Save',
              style: TextStyle(color: Color(0xFF1B5E20)),
            ),
            onPressed: () {
              if (_subjectController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty &&
                  _roomController.text.isNotEmpty &&
                  _teacherController.text.isNotEmpty) {
                setState(() {
                  _timetableData[_selectedDay]![index] = {
                    'subject': _subjectController.text,
                    'time': _timeController.text,
                    'room': _roomController.text,
                    'teacher': _teacherController.text,
                  };
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}