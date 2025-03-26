import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentAnnouncementsPage extends StatelessWidget {
  // Reference to the Firestore collection
  final CollectionReference _announcementsCollection = 
      FirebaseFirestore.instance.collection('announcements');
  
  // Stream to get announcements from Firestore
  Stream<QuerySnapshot> get _announcements {
    return _announcementsCollection
        .orderBy('date', descending: true)
        .snapshots();
  }

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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _announcements,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading announcements',
                          style: GoogleFonts.raleway(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No announcements available',
                          style: GoogleFonts.raleway(fontSize: 18),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // The StreamBuilder will automatically refresh when data changes
                        await Future.delayed(Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['date'] as Timestamp;

                          // Convert timestamp to readable date format
                          final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                          
                          // Determine announcement type (if not specified, default to 'general')
                          final type = data['type'] ?? 'general';
                          
                          // Create announcement map
                          final announcement = {
                            'title': data['title'],
                            'date': date,
                            'content': data['content'],
                            'type': type,
                          };
                          
                          return _buildAnnouncementCard(announcement);
                        },
                      ),
                    );
                  },
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
          // No need to manually refresh with StreamBuilder
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refreshing announcements...'))
          );
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
              // Show filter dialog
              _showFilterDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Announcements',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(context, 'All Announcements'),
            _buildFilterOption(context, 'Academic'),
            _buildFilterOption(context, 'Events'),
            _buildFilterOption(context, 'General'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.raleway(color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String filterName) {
    return ListTile(
      title: Text(
        filterName,
        style: GoogleFonts.raleway(),
      ),
      onTap: () {
        // Implement filter logic here
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtered by $filterName'))
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    IconData getIconForType(String type) {
      switch (type.toLowerCase()) {
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
            getIconForType(announcement['type']),
            color: Color(0xFF1B5E20),
            size: 24,
          ),
        ),
        title: Text(
          announcement['title'],
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          announcement['date'],
          style: GoogleFonts.raleway(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              announcement['content'],
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.share, size: 18),
                  label: Text('Share'),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.bookmark_border, size: 18),
                  label: Text('Save'),
                  onPressed: () {
                    // Implement save functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AnnouncementsPage extends StatelessWidget {
//   // Sample announcement data - in real app, this would come from an API or database
//   final List<Map<String, String>> announcements = [
//     {
//       'title': 'End Semester Examination Schedule',
//       'date': '2025-01-05',
//       'content': 'The end semester examinations will commence from January 15th. The detailed schedule has been published on the college website.',
//       'type': 'academic'
//     },
//     {
//       'title': 'College Sports Day',
//       'date': '2025-01-03',
//       'content': 'Annual sports day will be held on January 20th. All students are encouraged to participate.',
//       'type': 'event'
//     },
//     {
//       'title': 'Library Timing Update',
//       'date': '2025-01-01',
//       'content': 'The library will remain open until 8 PM on weekdays starting next week.',
//       'type': 'general'
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 const Color.fromARGB(255, 223, 243, 225),
//                 Colors.white,
//               ],
//             ),
//           ),
//           child: Column(
//             children: [
//               // App Bar
//               buildAppBar(context),
              
//               // Main Content
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     // Add refresh logic here
//                   },
//                   child: ListView.builder(
//                     padding: EdgeInsets.all(16),
//                     itemCount: announcements.length,
//                     itemBuilder: (context, index) {
//                       return _buildAnnouncementCard(announcements[index]);
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Color(0xFF1B5E20),
//         child: Icon(Icons.refresh),
//         onPressed: () {
//           // Add refresh logic here
//         },
//       ),
//     );
//   }

//   Widget buildAppBar(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//           Expanded(
//             child: Text(
//               'Announcements',
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1B5E20),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.filter_list, color: Color(0xFF1B5E20)),
//             onPressed: () {
//               // Add filter logic here
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnnouncementCard(Map<String, String> announcement) {
//     IconData getIconForType(String type) {
//       switch (type) {
//         case 'academic':
//           return Icons.school;
//         case 'event':
//           return Icons.event;
//         default:
//           return Icons.announcement;
//       }
//     }

//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ExpansionTile(
//         leading: Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Color(0xFF1B5E20).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             getIconForType(announcement['type']!),
//             color: Color(0xFF1B5E20),
//             size: 24,
//           ),
//         ),
//         title: Text(
//           announcement['title']!,
//           style: GoogleFonts.raleway(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         subtitle: Text(
//           announcement['date']!,
//           style: GoogleFonts.raleway(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//         children: [
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text(
//               announcement['content']!,
//               style: GoogleFonts.raleway(
//                 fontSize: 14,
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }