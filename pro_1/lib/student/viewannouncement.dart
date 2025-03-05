import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementsPage extends StatelessWidget {
  // Sample announcement data - in real app, this would come from an API or database
  final List<Map<String, String>> announcements = [
    {
      'title': 'End Semester Examination Schedule',
      'date': '2025-01-05',
      'content': 'The end semester examinations will commence from January 15th. The detailed schedule has been published on the college website.',
      'type': 'academic'
    },
    {
      'title': 'College Sports Day',
      'date': '2025-01-03',
      'content': 'Annual sports day will be held on January 20th. All students are encouraged to participate.',
      'type': 'event'
    },
    {
      'title': 'Library Timing Update',
      'date': '2025-01-01',
      'content': 'The library will remain open until 8 PM on weekdays starting next week.',
      'type': 'general'
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
              // App Bar
              buildAppBar(context),
              
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Add refresh logic here
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      return _buildAnnouncementCard(announcements[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1B5E20),
        child: Icon(Icons.refresh),
        onPressed: () {
          // Add refresh logic here
        },
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              'Announcements',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Color(0xFF1B5E20)),
            onPressed: () {
              // Add filter logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, String> announcement) {
    IconData getIconForType(String type) {
      switch (type) {
        case 'academic':
          return Icons.school;
        case 'event':
          return Icons.event;
        default:
          return Icons.announcement;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF1B5E20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getIconForType(announcement['type']!),
            color: Color(0xFF1B5E20),
            size: 24,
          ),
        ),
        title: Text(
          announcement['title']!,
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          announcement['date']!,
          style: GoogleFonts.raleway(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              announcement['content']!,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}