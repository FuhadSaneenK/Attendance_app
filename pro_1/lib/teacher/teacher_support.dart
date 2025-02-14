import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherSupport extends StatefulWidget {
  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<TeacherSupport> {
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Sample FAQ data
  final List<Map<String, dynamic>> faqs = [
    {
      'category': 'Attendance',
      'question': 'How do I modify attendance after submission?',
      'answer': 'To modify submitted attendance, go to the Attendance page, select the date and class, then click on "Edit Attendance". Make your changes and save them. Note that modifications can only be made within 24 hours of the original submission.'
    },
    {
      'category': 'Timetable',
      'question': 'How can I request a schedule change?',
      'answer': 'Schedule changes can be requested through the Timetable Management section. Click on "Request Change", select the classes you want to modify, propose new timings, and submit for admin approval.'
    },
    {
      'category': 'Technical',
      'question': 'What should I do if the app is not working?',
      'answer': 'First, try closing and reopening the app. If the issue persists, clear the app cache in your device settings. If problems continue, contact technical support through the Help Desk option below.'
    },
  ];

  // Sample support ticket data
  final List<Map<String, dynamic>> supportTickets = [
    {
      'id': 'TKT-001',
      'subject': 'Unable to access attendance module',
      'status': 'Open',
      'date': '2024-02-14',
      'priority': 'High'
    },
    {
      'id': 'TKT-002',
      'subject': 'Need help with timetable management',
      'status': 'Closed',
      'date': '2024-02-10',
      'priority': 'Medium'
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
                        _buildSupportOptions(),
                        SizedBox(height: 24),
                        _buildSearchBar(),
                        SizedBox(height: 24),
                        _buildFAQSection(),
                        SizedBox(height: 24),
                        _buildTicketsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new support ticket logic
        },
        backgroundColor: Color(0xFF1B5E20),
        child: Icon(Icons.add),
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
              'Help & Support',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Color(0xFF1B5E20)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildSupportOptionCard(
            'Help Desk',
            Icons.headset_mic,
            'Contact our support team',
            () {},
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSupportOptionCard(
            'User Guide',
            Icons.menu_book,
            'View documentation',
            () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSupportOptionCard(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: Color(0xFF1B5E20), size: 32),
              SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search for help',
        hintStyle: GoogleFonts.raleway(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search, color: Color(0xFF1B5E20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All'),
              SizedBox(width: 8),
              _buildCategoryChip('Attendance'),
              SizedBox(width: 8),
              _buildCategoryChip('Timetable'),
              SizedBox(width: 8),
              _buildCategoryChip('Technical'),
            ],
          ),
        ),
        SizedBox(height: 16),
        ...faqs
            .where((faq) =>
                selectedCategory == 'All' || faq['category'] == selectedCategory)
            .map((faq) => _buildFAQCard(faq))
            .toList(),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
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
        setState(() => selectedCategory = label);
      },
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              faq['answer'],
              style: GoogleFonts.raleway(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Support Tickets',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        SizedBox(height: 16),
        ...supportTickets.map((ticket) => _buildTicketCard(ticket)),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    Color statusColor = ticket['status'] == 'Open' ? Colors.orange : Colors.green;
    Color priorityColor = ticket['priority'] == 'High' ? Colors.red : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Add ticket details navigation
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ticket['id'],
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket['status'],
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                ticket['subject'],
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Date: ${ticket['date']}',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.flag, size: 16, color: priorityColor),
                  SizedBox(width: 4),
                  Text(
                    ticket['priority'],
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}