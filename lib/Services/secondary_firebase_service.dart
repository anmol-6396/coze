import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper service for [coze] app to communicate with both Firebase projects:
/// 1. [coze-anmol]   -> Student / Main App Firebase Project (Default)
/// 2. [coze-teacher] -> Teacher App Firebase Project
class SecondaryFirebaseService {
  static FirebaseApp? _teacherApp;
  static FirebaseApp? _studentApp;

  /// Teacher App Firebase Project Configuration (coze-teacher)
  static const FirebaseOptions teacherFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyBiVpLZOuJr29av3iUiAFpPB87-8tqRBp8',
    appId: '1:951302145563:android:62e651b58288b9a549dabe',
    messagingSenderId: '951302145563',
    projectId: 'coze-teacher',
    storageBucket: 'coze-teacher.firebasestorage.app',
  );

  /// Student / Main App Firebase Project Configuration (coze-anmol)
  static const FirebaseOptions studentFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyAPRgYNsl6vQrTyKQEwEts37LaIFcCT3PI',
    appId: '1:398665331927:android:fe1db831f74d330c9f2c92',
    messagingSenderId: '398665331927',
    projectId: 'coze-anmol',
    storageBucket: 'coze-anmol.firebasestorage.app',
  );

  /// Get [coze-teacher] (Teacher) Firebase App instance
  static Future<FirebaseApp> getTeacherApp() async {
    if (_teacherApp != null) return _teacherApp!;
    try {
      _teacherApp = Firebase.app('TeacherFirebaseProject');
    } catch (_) {
      _teacherApp = await Firebase.initializeApp(
        name: 'TeacherFirebaseProject',
        options: teacherFirebaseOptions,
      );
    }
    return _teacherApp!;
  }

  /// Get [coze-anmol] (Student) Firebase App instance
  static Future<FirebaseApp> getStudentApp() async {
    if (_studentApp != null) return _studentApp!;
    try {
      _studentApp = Firebase.app('StudentFirebaseProject');
    } catch (_) {
      _studentApp = await Firebase.initializeApp(
        name: 'StudentFirebaseProject',
        options: studentFirebaseOptions,
      );
    }
    return _studentApp!;
  }

  /// Firestore instance for Teacher App Database (coze-teacher)
  static Future<FirebaseFirestore> getTeacherFirestore() async {
    final app = await getTeacherApp();
    return FirebaseFirestore.instanceFor(app: app);
  }

  /// Firestore instance for Student App Database (coze-anmol)
  static Future<FirebaseFirestore> getStudentFirestore() async {
    final app = await getStudentApp();
    return FirebaseFirestore.instanceFor(app: app);
  }

  /// Increments action count for a teacher in the Teacher App Database (coze-teacher)
  static Future<void> incrementTeacherActionCount({
    required String teacherDocId,
    required String actionField,
    String collectionName = 'action_counts',
  }) async {
    try {
      final firestore = await getTeacherFirestore();
      await firestore.collection(collectionName).doc(teacherDocId).set({
        actionField: FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error incrementing teacher action count from coze app: $e');
    }
  }

  /// Stream teacher ads or profiles directly from Teacher Database (coze-teacher)
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamTeacherCollection(String collectionName) async* {
    final firestore = await getTeacherFirestore();
    yield* firestore.collection(collectionName).snapshots();
  }

  /// Write student action or request directly to Teacher Database (coze-teacher)
  static Future<void> sendRequestToTeacher(String docId, Map<String, dynamic> requestData) async {
    final firestore = await getTeacherFirestore();
    await firestore.collection('teacher_requests').doc(docId).set(requestData, SetOptions(merge: true));
  }
}
