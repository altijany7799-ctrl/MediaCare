import 'package:flutter/material.dart';
import '../services/doctor_admin_service.dart';

class DoctorAdminScreen extends StatefulWidget {
  const DoctorAdminScreen({super.key});

  @override
  State<DoctorAdminScreen> createState() =>
      _DoctorAdminScreenState();
}

class _DoctorAdminScreenState
    extends State<DoctorAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _workingHoursController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await DoctorAdminService.updateDoctor(
        doctorId: _idController.text.trim(),
        data: {
          'name': _nameController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'experience':
              int.parse(_experienceController.text.trim()),
          'workingHours': _workingHoursController.text.trim(),
          'location': _locationController.text.trim(),
          'bio': _bioController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات الطبيب بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : TextInputType.text,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          if (number && int.tryParse(value.trim()) == null) {
            return 'أدخل رقمًا صحيحًا';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بيانات الأطباء'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field('معرّف الطبيب في Firestore', _idController),
            _field('اسم الطبيب', _nameController),
            _field('التخصص', _specialtyController),
            _field(
              'سنوات الخبرة',
              _experienceController,
              number: true,
            ),
            _field('ساعات العمل', _workingHoursController),
            _field('الموقع أو المستشفى', _locationController),
            _field('نبذة عن الطبيب', _bioController, lines: 3),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saving ? null : _saveDoctor,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF0D6E78),
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}