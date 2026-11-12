import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState
    extends State<DoctorDashboardScreen> {
  bool _saving = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _doctorRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('doctors').doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? get _doctorStream {
    return _doctorRef?.snapshots();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateDoctor(
    Map<String, dynamic> values,
  ) async {
    final reference = _doctorRef;

    if (reference == null) {
      _message('يرجى تسجيل الدخول أولاً');
      return;
    }

    setState(() => _saving = true);

    try {
      await reference.update({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _message('تم حفظ التعديلات بنجاح');
    } on FirebaseException catch (e) {
      _message(
        e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لتعديل هذه البيانات'
            : 'تعذر الحفظ: ${e.message ?? e.code}',
      );
    } catch (e) {
      _message('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editHours(String currentHours) async {
    final controller = TextEditingController(text: currentHours);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل ساعات العمل'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'أوقات الدوام',
              hintText: 'مثال: الأحد - الخميس، 09:00 - 17:00',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (result != null) {
      await _updateDoctor({'workingHours': result});
    }
  }

  Future<void> _updateAppointment(
    String appointmentId,
    String status,
  ) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      _message(
        status == 'confirmed'
            ? 'تم قبول الموعد'
            : status == 'rejected'
                ? 'تم رفض الموعد'
                : 'تم تحديث الموعد',
      );
    } on FirebaseException catch (e) {
      _message(
        e.code == 'permission-denied'
            ? 'قواعد Firestore لا تسمح بتحديث هذا الموعد بعد'
            : 'تعذر تحديث الموعد: ${e.message ?? e.code}',
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الطبيب'),
          backgroundColor: const Color(0xFF0D6E78),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: _doctorStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('تعذر تحميل بيانات الطبيب'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final document = snapshot.data;

            if (document == null || !document.exists) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لم يتم العثور على ملف طبيب مرتبط بحسابك. '
                    'تأكد من موافقة الأدمن وربط حسابك بسجل doctors.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final doctor = document.data()!;

            if (doctor['uid'] != _uid ||
                doctor['isActive'] != true) {
              return const Center(
                child: Text(
                  'حساب الطبيب غير مرتبط أو غير مفعّل. '
                  'يرجى التواصل مع الأدمن.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final name = doctor['name']?.toString() ?? 'الطبيب';
            final specialty =
                doctor['specialty']?.toString() ?? 'غير محدد';
            final hours =
                doctor['workingHours']?.toString() ?? '';
            final available = doctor['isAvailable'] == true;

            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              child: Icon(
                                Icons.medical_services,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ),
                                  ),
                                  Text(specialty),
                                  Text(
                                    'ساعات العمل: ${hours.isEmpty ? 'لم تحدد بعد' : hours}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => _editHours(hours),
                              icon: const Icon(Icons.edit),
                              tooltip: 'تعديل ساعات العمل',
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('استقبال حجوزات جديدة'),
                          subtitle: Text(
                            available
                                ? 'متاح حاليًا'
                                : 'غير متاح حاليًا',
                          ),
                          value: available,
                          onChanged: _saving
                              ? null
                              : (value) => _updateDoctor({
                                    'isAvailable': value,
                                  }),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مواعيد المرضى',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection('appointments')
                        .where('doctorId', isEqualTo: document.id)
                        .snapshots(),
                    builder: (context, appointmentSnapshot) {
                      if (appointmentSnapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'تعذر تحميل المواعيد. تحقق من قواعد Firestore '
                              'وأن doctorId في كل حجز يطابق معرّف الطبيب.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (appointmentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final items =
                          appointmentSnapshot.data?.docs ?? [];

                      if (items.isEmpty) {
                        return const Center(
                          child: Text('لا توجد مواعيد لهذا الطبيب'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final data = item.data();
                          final status =
                              data['status']?.toString() ?? 'pending';

                          final pending = [
                            'pending',
                            'upcoming',
                          ].contains(status.toLowerCase());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['patientName']?.toString() ??
                                        data['userName']?.toString() ??
                                        'مريض',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'التاريخ: ${data['date'] ?? data['appointmentDate'] ?? 'غير محدد'}',
                                  ),
                                  Text(
                                    'الوقت: ${data['time'] ?? data['appointmentTime'] ?? 'غير محدد'}',
                                  ),
                                  Text('الحالة: $status'),
                                  if (pending) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _updateAppointment(
                                            item.id,
                                            'confirmed',
                                          ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('قبول'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _updateAppointment(
                                            item.id,
                                            'rejected',
                                          ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('رفض'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}