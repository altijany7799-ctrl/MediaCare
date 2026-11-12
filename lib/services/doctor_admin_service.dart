import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorAdminService {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static const String adminUid =
      '4SRutGLlc3QxKUURSymYwWCNb9H3';

  static Future<void> updateDoctor({
    required String doctorId,
    required Map<String, dynamic> data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != adminUid) {
      throw Exception(
        'غير مصرح لك بتعديل بيانات الأطباء',
      );
    }

    if (data.isEmpty) {
      throw Exception('لا توجد بيانات للتعديل');
    }

    await _db
        .collection('doctors')
        .doc(doctorId)
        .update(data);
  }
}