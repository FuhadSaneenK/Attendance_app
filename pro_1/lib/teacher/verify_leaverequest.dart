import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveRequestsPage extends StatefulWidget {
  @override
  _LeaveRequestsPageState createState() => _LeaveRequestsPageState();
}

class _LeaveRequestsPageState extends State<LeaveRequestsPage> {
  String selectedFilter = 'All';
  
  // Sample leave request data
  final List<Map<String, dynamic>> leaveRequests = [
    {
      'studentName': 'Alice Smith',
      'studentId': '2024001',
      'class': 'Class 10A',
      'fromDate': '2024-02-15',
      'toDate': '2024-02-16',
      'reason': 'Medical appointment',
      'status': 'Pending',
      'attachmentUrl': 'medical_certificate.pdf'
    },
    {
      'studentName': 'Bob Johnson',
      'studentId': '2024002',
      'class': 'Class 10A',
      'fromDate': '2024-02-18',
      'toDate': '2024-02-18',
      'reason': 'Family function',
      'status': 'Approved',
      'attachmentUrl': null
    },
    {
      'studentName': 'Carol White',
      'studentId': '2024003',
      'class': 'Class 11B',
      'fromDate': '2024-02-14',
      'toDate': '2024-02-14',
      'reason': 'Religious festival',
      'status': 'Rejected',
      'attachmentUrl': null
    },
  ];

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
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        SizedBox(height: 24),
                        _buildFilterSection(),
                        SizedBox(height: 16),
                        ...leaveRequests.map((request) => _buildLeaveRequestCard(request)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Leave Requests',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF1B5E20)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            '5',
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Approved',
            '12',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Rejected',
            '3',
            Icons.cancel_outlined,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.raleway(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All'),
          SizedBox(width: 8),
          _buildFilterChip('Pending'),
          SizedBox(width: 8),
          _buildFilterChip('Approved'),
          SizedBox(width: 8),
          _buildFilterChip('Rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: GoogleFonts.raleway(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: Color(0xFF1B5E20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Color(0xFF1B5E20) : Colors.grey.shade300,
        ),
      ),
      onSelected: (bool selected) {
        setState(() => selectedFilter = label);
      },
    );
  }

  Widget _buildLeaveRequestCard(Map<String, dynamic> request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request['status']) {
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['studentName'],
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${request['studentId']} | ${request['class']}',
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        request['status'],
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Date: ${request['fromDate']} to ${request['toDate']}',
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Reason: ${request['reason']}',
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            if (request['attachmentUrl'] != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Attachment',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            if (request['status'] == 'Pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Add reject logic
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.raleway(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Add approve logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}