import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SemesterDetailsForm extends StatefulWidget {
  @override
  _SemesterDetailsFormState createState() => _SemesterDetailsFormState();
}

class _SemesterDetailsFormState extends State<SemesterDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _workingDaysController = TextEditingController();
  
  List<DateTime> _holidays = [];
  
  // Simplified semester options
  final List<String> semesters = [
    'Even Semester',
    'Odd Semester',
  ];
  
  String? _selectedSemester;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _workingDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1B5E20),
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
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectHoliday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1B5E20),
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
        if (!_holidays.contains(picked)) {
          _holidays.add(picked);
        }
      });
    }
  }

  void _removeHoliday(DateTime holiday) {
    setState(() {
      _holidays.remove(holiday);
    });
  }


void _saveSemesterDetails() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Format holidays list for Firestore
      final List<String> formattedHolidays = _holidays
          .map((holiday) => DateFormat('yyyy-MM-dd').format(holiday))
          .toList();

      // Create semester details map
      final Map<String, dynamic> semesterDetails = {
        'semester': _selectedSemester,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'working_days': int.parse(_workingDaysController.text),
        'holidays': formattedHolidays,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore in the attendance collection as 'current semester'
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc('current_semester')
          .set(semesterDetails);

      print('Semester Details saved to Firestore: $semesterDetails');
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semester details saved to database successfully!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      
      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedSemester = null;
        _startDateController.clear();
        _endDateController.clear();
        _workingDaysController.clear();
        _holidays.clear();
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving semester details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error saving semester details: $e');
    }
  }
}


  // void _saveSemesterDetails() {
  //   if (_formKey.currentState!.validate()) {
  //     // Here you'd normally save the data to your backend
  //     // For now, we'll just print the values

  //     final List<String> formattedHolidays = _holidays
  //         .map((holiday) => DateFormat('yyyy-MM-dd').format(holiday))
  //         .toList();

  //     final Map<String, dynamic> semesterDetails = {
  //       'semester': _selectedSemester,
  //       'start_date': _startDateController.text,
  //       'end_date': _endDateController.text,
  //       'working_days': int.parse(_workingDaysController.text),
  //       'holidays': formattedHolidays,
  //     };

  //     print('Semester Details: $semesterDetails');
      
  //     // Show success snackbar
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Semester details added successfully!'),
  //         backgroundColor: Color(0xFF1B5E20),
  //       ),
  //     );
      
  //     // Reset form
  //     _formKey.currentState!.reset();
  //     setState(() {
  //       _selectedSemester = null;
  //       _startDateController.clear();
  //       _endDateController.clear();
  //       _workingDaysController.clear();
  //       _holidays.clear();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Semester Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: 24),
          
          // Semester Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Semester Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF1B5E20)),
            ),
            value: _selectedSemester,
            items: semesters.map((String semester) {
              return DropdownMenuItem<String>(
                value: semester,
                child: Text(semester),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSemester = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select a semester type' : null,
          ),
          SizedBox(height: 16),
          
          // Start Date
          TextFormField(
            controller: _startDateController,
            decoration: InputDecoration(
              labelText: 'Start Date',
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.date_range, color: Color(0xFF1B5E20)),
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                onPressed: () => _selectDate(context, _startDateController),
              ),
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter start date';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          // End Date
          TextFormField(
            controller: _endDateController,
            decoration: InputDecoration(
              labelText: 'End Date',
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.date_range, color: Color(0xFF1B5E20)),
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                onPressed: () => _selectDate(context, _endDateController),
              ),
            ),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter end date';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          // Working Days
          TextFormField(
            controller: _workingDaysController,
            decoration: InputDecoration(
              labelText: 'Working Days',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work, color: Color(0xFF1B5E20)),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter number of working days';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          
          // Holidays Section
          Text(
            'Holidays',
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: 8),
          
          // Display selected holidays
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_holidays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No holidays added yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _holidays.map((holiday) {
                      return Chip(
                        backgroundColor: Color(0xFFE8F5E9),
                        label: Text(DateFormat('yyyy-MM-dd').format(holiday)),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () => _removeHoliday(holiday),
                      );
                    }).toList(),
                  ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectHoliday(context),
                  icon: Icon(Icons.add),
                  label: Text('Add Holiday'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          
          // Submit Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSemesterDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save Semester Details'),
            ),
          ),
        ],
      ),
    );
  }
}