const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.createStudentUsers = functions.https.onCall(async (data, context) => {
  try {
    const students = data.students;
    
    if (!students || !Array.isArray(students)) {
      throw new functions.https.HttpsError('invalid-argument', 'Students data is required and must be an array');
    }
    
    const results = [];
    
    for (const student of students) {
      try {
        // Create user in Firebase Authentication
        const userRecord = await admin.auth().createUser({
          email: student.username,
          password: student.password,
          displayName: student.name
        });
        
        // Add custom claims to identify user as student
        await admin.auth().setCustomUserClaims(userRecord.uid, { 
          role: 'student',
          admissionNo: student.admissionNo
        });
        
        results.push({
          success: true,
          admissionNo: student.admissionNo,
          uid: userRecord.uid
        });
      } catch (error) {
        results.push({
          success: false,
          admissionNo: student.admissionNo,
          error: error.message
        });
      }
    }
    
    return { results };
  } catch (error) {
    throw new functions.https.HttpsError('internal', `Error creating users: ${error.message}`);
  }
});


// /**
//  * Import function triggers from their respective submodules:
//  *
//  * const {onCall} = require("firebase-functions/v2/https");
//  * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });
