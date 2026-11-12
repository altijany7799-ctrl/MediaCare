import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  static const Color primaryColor = Color(0xFF0D6E78);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('يرجى تسجيل الدخول لعرض مواعيدك')),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'مواعيدي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return _MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'تعذر تحميل المواعيد',
                subtitle: 'تحقق من اتصال الإنترنت وصلاحيات قاعدة البيانات.',
                onRetry: () {},
              );
            }

            final appointments = [...?snapshot.data?.docs];

            appointments.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];

              final aDate = aTime is Timestamp
                  ? aTime.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);

              final bDate = bTime is Timestamp
                  ? bTime.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);

              return bDate.compareTo(aDate);
            });

            if (appointments.isEmpty) {
              return const _MessageView(
                icon: Icons.calendar_month_outlined,
                title: 'لا توجد مواعيد حالياً',
                subtitle: 'عند حجز موعد سيظهر هنا',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final document = appointments[index];
                final data = document.data();

                return AppointmentCard(
                  key: ValueKey(document.id),
                  appointmentId: document.id,
                  doctorName: _readText(data, [
                    'doctorName',
                    'doctor_name',
                    'name',
                  ], fallback: 'طبيب'),
                  specialty: _readText(data, [
                    'specialty',
                    'doctorSpecialty',
                  ], fallback: 'غير محدد'),
                  date: _readDate(data['date'] ?? data['appointmentDate']),
                  time: _readText(data, [
                    'time',
                    'appointmentTime',
                  ], fallback: 'غير محدد'),
                  status: _readText(data, ['status'], fallback: 'pending'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _readText(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static String _readDate(dynamic value) {
    if (value == null) return 'غير محدد';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
      if (date == null) return value;
    }

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class AppointmentCard extends StatefulWidget {
  final String appointmentId;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  static const Color primaryColor = Color(0xFF0D6E78);

  bool isCancelling = false;

  String get normalizedStatus {
    switch (widget.status.trim().toLowerCase()) {
      case 'cancelled':
      case 'canceled':
      case 'ملغى':
      case 'ملغي':
        return 'cancelled';

      case 'confirmed':
      case 'مؤكد':
        return 'confirmed';

      case 'completed':
      case 'مكتمل':
        return 'completed';

      case 'rejected':
      case 'مرفوض':
        return 'rejected';

      default:
        return 'pending';
    }
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'cancelled':
        return 'ملغى';
      case 'confirmed':
        return 'مؤكد';
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'قيد الانتظار';
    }
  }

  Color get statusColor {
    switch (normalizedStatus) {
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange.shade800;
    }
  }

  bool get canCancel =>
      normalizedStatus != 'cancelled' &&
      normalizedStatus != 'rejected' &&
      normalizedStatus != 'completed';

  Future<void> _cancelAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('يرجى تسجيل الدخول أولاً');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('إلغاء الموعد'),
            content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('العودة'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد الإلغاء'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => isCancelling = true);

    try {
      final reference = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId);

      final document = await reference.get();

      if (!document.exists) {
        throw Exception('الموعد غير موجود');
      }

      final data = document.data();

      if (data == null || data['userId'] != user.uid) {
        throw Exception('لا يمكنك إلغاء هذا الموعد');
      }

      final currentStatus = (data['status'] ?? 'pending')
          .toString()
          .toLowerCase();

      if (currentStatus == 'cancelled' ||
          currentStatus == 'canceled' ||
          currentStatus == 'ملغى' ||
          currentStatus == 'ملغي') {
        _showMessage('هذا الموعد ملغى بالفعل');
        return;
      }

      if (currentStatus == 'completed' || currentStatus == 'مكتمل') {
        _showMessage('لا يمكن إلغاء موعد مكتمل');
        return;
      }

      await reference.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      _showMessage('تم إلغاء الموعد بنجاح');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showMessage('ليس لديك صلاحية الإلغاء. تحقق من قواعد Firestore.');
      } else {
        _showMessage('تعذر إلغاء الموعد: ${e.message ?? e.code}');
      }
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isCancelling = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F2F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 38,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctorName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: primaryColor,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 20, color: primaryColor),
                const SizedBox(width: 7),
                Text(
                  widget.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isCancelling ? null : _cancelAppointment,
                icon: isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(isCancelling ? 'جارٍ الإلغاء...' : 'إلغاء الموعد'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.6),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
