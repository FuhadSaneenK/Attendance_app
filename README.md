# Attendance Management System  
*A cross-platform attendance and academic management application built using Flutter, Dart, and Firebase.*

---

## Overview  
The **Attendance Management System** is a **mobile and web-based application** developed using **Flutter** and **Firebase**.  
It provides an efficient digital platform for **managing attendance, uploading academic notes, and monitoring student performance**.  
The system supports separate interfaces for **administrators, teachers, and students**, ensuring smooth communication and data management across all roles.

The project demonstrates the use of **Flutter for cross-platform UI** (Android, iOS, and Web) and **Firebase** as the backend for real-time database management, authentication, and cloud storage.

---

## Objectives  
- To develop a **cross-platform solution** for attendance and academic management.  
- To ensure **secure user authentication** and role-based access for admin, teachers, and students.  
- To automate the **attendance marking process** and maintain digital records.  
- To provide **real-time updates** using Firebase Cloud Firestore.  
- To offer features like **note uploads**, **attendance reports**, and **performance tracking**.

---

## Key Features  
### 👩‍🏫 Admin Panel
- Add and manage **teachers and students**.  
- Monitor overall attendance statistics.  
- Manage class and course information.  
- Upload important notices or materials for students.  

### 📚 Teacher Interface
- Mark student attendance digitally.  
- Upload class materials and notes.  
- View student lists and attendance reports.  
- Manage multiple classes and subjects.  

### 👨‍🎓 Student Interface
- Log in securely using Firebase Authentication.  
- View personal attendance records and statistics.  
- Access uploaded notes and announcements.  
- Receive updates from teachers and admin in real-time.  

---

## Tech Stack  
| Layer | Technology Used |
|-------|------------------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase |
| **Database** | Firebase Cloud Firestore |
| **Authentication** | Firebase Authentication |
| **Cloud Storage** | Firebase Storage |
| **Platforms Supported** | Android, iOS, Web |

---

---

## Installation & Setup  


```bash
### 1. Clone the Repository  
git clone https://github.com/FuhadSaneenK/Attendance_app.git
cd Attendance_app/pro_1

2. Install Dependencies
flutter pub get

3. Connect to Firebase

Go to Firebase Console
.

Create a new Firebase project.

Add Android, iOS, and Web apps to the project.

Download the google-services.json (for Android) and GoogleService-Info.plist (for iOS).

Place them in their respective platform folders.

Enable Firestore Database, Authentication, and Storage in Firebase Console.
