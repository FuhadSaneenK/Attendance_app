import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';

class AnnouncementsPage extends StatefulWidget {
  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // Text controllers for creating new announcement
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  // Reference to the Firestore collection
  final CollectionReference _announcementsCollection = 
      FirebaseFirestore.instance.collection('announcements');

  // Fetch announcements from Firestore
  Stream<QuerySnapshot> get _announcements {
    return _announcementsCollection
        .orderBy('date', descending: true)
        .snapshots();
  }

  void _showCreateAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create New Announcement',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Announcement Title',
                hintStyle: GoogleFonts.raleway(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Announcement Details',
                hintStyle: GoogleFonts.raleway(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _titleController.clear();
              _contentController.clear();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.raleway(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                // Add new announcement to Firestore
                _addAnnouncement();
                Navigator.of(context).pop();
                _titleController.clear();
                _contentController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B5E20),
            ),
            child: Text(
              'Post',
              style: GoogleFonts.raleway(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Add a new announcement to Firestore
  Future<void> _addAnnouncement() async {
    try {
      await _announcementsCollection.add({
        'title': _titleController.text,
        'content': _contentController.text,
        'date': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement posted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting announcement: $e')),
      );
    }
  }

  // Delete an announcement from Firestore
  Future<void> _deleteAnnouncement(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Announcement',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this announcement?',
          style: GoogleFonts.raleway(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.raleway(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _announcementsCollection.doc(id).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Announcement deleted successfully')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting announcement: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.raleway(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Announcements',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: Color(0xFF1B5E20),
        child: Icon(Icons.add),
      ),
      body: Container(
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

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['date'] as Timestamp;
                final date = timestamp.toDate();

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'],
                            style: GoogleFonts.raleway(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteAnnouncement(doc.id),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          data['content'],
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _formatDate(date),
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}



// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AnnouncementsPage extends StatefulWidget {
//   @override
//   _AnnouncementsPageState createState() => _AnnouncementsPageState();
// }

// class _AnnouncementsPageState extends State<AnnouncementsPage> {
//   // Sample announcements list
//   final List<Announcement> announcements = [
//     Announcement(
//       id: '1',
//       title: 'Mid-Term Exams Schedule',
//       content: 'Mid-term examinations will start from 15th March. All students are advised to prepare accordingly.',
//       date: DateTime.now().subtract(Duration(days: 2)),
//     ),
//     Announcement(
//       id: '2',
//       title: 'Annual Sports Day',
//       content: 'Our school\'s annual sports day is scheduled for 20th April. Students can register for various events.',
//       date: DateTime.now().subtract(Duration(days: 5)),
//     ),
//   ];

//   // Text controllers for creating new announcement
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _contentController = TextEditingController();

//   void _showCreateAnnouncementDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Create New Announcement',
//           style: GoogleFonts.playfairDisplay(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: InputDecoration(
//                 hintText: 'Announcement Title',
//                 hintStyle: GoogleFonts.raleway(),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _contentController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Announcement Details',
//                 hintStyle: GoogleFonts.raleway(),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _titleController.clear();
//               _contentController.clear();
//             },
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.raleway(color: Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
//                 setState(() {
//                   announcements.insert(0, Announcement(
//                     id: DateTime.now().millisecondsSinceEpoch.toString(),
//                     title: _titleController.text,
//                     content: _contentController.text,
//                     date: DateTime.now(),
//                   ));
//                 });
//                 Navigator.of(context).pop();
//                 _titleController.clear();
//                 _contentController.clear();
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF1B5E20),
//             ),
//             child: Text(
//               'Post',
//               style: GoogleFonts.raleway(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deleteAnnouncement(String id) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Delete Announcement',
//           style: GoogleFonts.playfairDisplay(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.red,
//           ),
//         ),
//         content: Text(
//           'Are you sure you want to delete this announcement?',
//           style: GoogleFonts.raleway(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.raleway(color: Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 announcements.removeWhere((announcement) => announcement.id == id);
//               });
//               Navigator.of(context).pop();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: Text(
//               'Delete',
//               style: GoogleFonts.raleway(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           'Announcements',
//           style: GoogleFonts.playfairDisplay(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showCreateAnnouncementDialog,
//         backgroundColor: Color(0xFF1B5E20),
//         child: Icon(Icons.add),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               const Color.fromARGB(255, 223, 243, 225),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: ListView.builder(
//           padding: EdgeInsets.all(16),
//           itemCount: announcements.length,
//           itemBuilder: (context, index) {
//             final announcement = announcements[index];
//             return Container(
//               margin: EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: ListTile(
//                 contentPadding: EdgeInsets.all(16),
//                 title: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         announcement.title,
//                         style: GoogleFonts.raleway(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1B5E20),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete_outline, color: Colors.red),
//                       onPressed: () => _deleteAnnouncement(announcement.id),
//                     ),
//                   ],
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(height: 8),
//                     Text(
//                       announcement.content,
//                       style: GoogleFonts.raleway(
//                         fontSize: 16,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Text(
//                       _formatDate(announcement.date),
//                       style: GoogleFonts.raleway(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day} ${_getMonthName(date.month)} ${date.year}';
//   }

//   String _getMonthName(int month) {
//     const months = [
//       'January', 'February', 'March', 'April', 'May', 'June', 
//       'July', 'August', 'September', 'October', 'November', 'December'
//     ];
//     return months[month - 1];
//   }
// }

// class Announcement {
//   final String id;
//   final String title;
//   final String content;
//   final DateTime date;

//   Announcement({
//     required this.id,
//     required this.title,
//     required this.content,
//     required this.date,
//   });
// }