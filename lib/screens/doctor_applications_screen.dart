import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorApplicationsScreen extends StatelessWidget {
  const DoctorApplicationsScreen({super.key});

  static const String adminUid =
      '4SRutGLlc3QxKUURSymYwWCNb9H3';

  Future<void> _reviewApplication(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool approve,
  ) async {
    try {
      final data = doc.data();

      if (approve) {
        final doctorData = <String, dynamic>{
          'uid': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'specialty': data['specialty'] ?? '',
          'phone': data['phone'] ?? '',
          'isActive': true,
          'isAvailable': false,
          'rating': 0.0,
          'experience': 0,
          'workingHours': '',
          'location': '',
          'bio': '',
        };

        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        batch.set(
          firestore.collection('doctors').doc(doc.id),
          doctorData,
        );

        batch.update(
          firestore.collection('doctorApplications').doc(doc.id),
          {
            'status': 'approved',
            'reviewedAt': FieldValue.serverTimestamp(),
          },
        );

        await batch.commit();
      } else {
        await FirebaseFirestore.instance
            .collection('doctorApplications')
            .doc(doc.id)
            .update({
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'تمت الموافقة وإنشاء سجل الطبيب'
                : 'تم رفض طلب الطبيب',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات تسجيل الأطباء'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctorApplications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('تعذر تحميل الطلبات'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد طلبات تسجيل جديدة'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'بدون اسم',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('البريد: ${data['email'] ?? '-'}'),
                      Text('التخصص: ${data['specialty'] ?? '-'}'),
                      Text('الهاتف: ${data['phone'] ?? '-'}'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _reviewApplication(
                                context,
                                doc,
                                true,
                              ),
                              child: const Text('موافقة'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _reviewApplication(
                                context,
                                doc,
                                false,
                              ),
                              child: const Text('رفض'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}