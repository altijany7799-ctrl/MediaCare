import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() =>
      _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState
    extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _specialty = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _specialty.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    User? createdUser;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('تعذر إنشاء الحساب');
      }

      await FirebaseFirestore.instance
          .collection('doctorApplications')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'specialty': _specialty.text.trim(),
        'phone': _phone.text.trim(),
        'status': 'pending',
        'isActive': false,
        'isAvailable': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال طلبك للأدمن. انتظر الموافقة قبل تسجيل الدخول كطبيب.',
          ),
          duration: Duration(seconds: 5),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('doctorApplications')
              .doc(createdUser.uid)
              .delete();
          await createdUser.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      final message = switch (e.code) {
        'email-already-in-use' => 'هذا البريد مسجل بالفعل',
        'weak-password' => 'كلمة المرور ضعيفة',
        'invalid-email' => 'البريد الإلكتروني غير صحيح',
        _ => 'تعذر التسجيل: ${e.message ?? e.code}',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (createdUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('doctorApplications')
              .doc(createdUser.uid)
              .delete();
          await createdUser.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: password && _hidePassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) return 'هذا الحقل مطلوب';

          if (password && (value?.length ?? 0) < 6) {
            return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
          }

          if (label == 'البريد الإلكتروني' &&
              !text.contains('@')) {
            return 'أدخل بريدًا إلكترونيًا صحيحًا';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل حساب طبيب')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'إنشاء حساب طبيب جديد',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم مراجعة طلبك من الأدمن قبل تفعيل حساب الطبيب.',
            ),
            const SizedBox(height: 24),
            _field('اسم الطبيب', _name),
            _field('البريد الإلكتروني', _email,
                keyboardType: TextInputType.emailAddress),
            _field('التخصص', _specialty),
            _field('رقم الهاتف', _phone,
                keyboardType: TextInputType.phone),
            _field('كلمة المرور', _password, password: true),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('إرسال طلب التسجيل'),
            ),
          ],
        ),
      ),
    );
  }
}