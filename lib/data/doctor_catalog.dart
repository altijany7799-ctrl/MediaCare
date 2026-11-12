import 'package:firebase_core/firebase_core.dart';

String get sampleDoctorsNotice =>
    'لا توجد سجلات في مجموعة doctors ضمن مشروع '
    '${Firebase.app().options.projectId}. تُعرض بيانات تجريبية مؤقتة.';

const sampleDoctors = <Map<String, dynamic>>[
  {
    'name': 'د. أحمد محمد',
    'specialty': 'الأسنان',
    'category': 'الأسنان',
    'rating': 4.9,
  },
  {
    'name': 'د. سارة خالد',
    'specialty': 'الأسنان',
    'category': 'الأسنان',
    'rating': 4.8,
  },
  {
    'name': 'د. مريم علي',
    'specialty': 'العيون',
    'category': 'العيون',
    'rating': 4.9,
  },
  {
    'name': 'د. يوسف إبراهيم',
    'specialty': 'العيون',
    'category': 'العيون',
    'rating': 4.7,
  },
  {
    'name': 'د. خالد حسن',
    'specialty': 'القلب',
    'category': 'القلب',
    'rating': 4.9,
  },
  {
    'name': 'د. نور عبد الله',
    'specialty': 'القلب',
    'category': 'القلب',
    'rating': 4.8,
  },
  {
    'name': 'د. عمر سعيد',
    'specialty': 'العظام',
    'category': 'العظام',
    'rating': 4.8,
  },
  {
    'name': 'د. ليلى محمود',
    'specialty': 'العظام',
    'category': 'العظام',
    'rating': 4.7,
  },
  {
    'name': 'د. منى عبد الرحمن',
    'specialty': 'الباطنية',
    'category': 'الباطنية',
    'rating': 4.9,
  },
  {
    'name': 'د. سامي مصطفى',
    'specialty': 'الباطنية',
    'category': 'الباطنية',
    'rating': 4.6,
  },
  {
    'name': 'د. هدى أحمد',
    'specialty': 'المسالك البولية',
    'category': 'المسالك البولية',
    'rating': 4.8,
  },
  {
    'name': 'د. مازن فؤاد',
    'specialty': 'المسالك البولية',
    'category': 'المسالك البولية',
    'rating': 4.7,
  },
];

String normalizeDoctorSpecialty(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\s_\-،,./]+'), '');
}

String canonicalDoctorSpecialty(String value) {
  final normalized = normalizeDoctorSpecialty(value);
  const aliases = <String, List<String>>{
    'الأسنان': [
      'الاسنان',
      'اسنان',
      'طب الاسنان',
      'طبيب الاسنان',
      'dentistry',
      'dentist',
      'dental',
    ],
    'العيون': [
      'العيون',
      'عيون',
      'طب العيون',
      'طب وجراحة العيون',
      'ophthalmology',
      'ophthalmologist',
      'eye',
      'eyes',
    ],
    'القلب': [
      'القلب',
      'قلب',
      'امراض القلب',
      'أمراض القلب',
      'طب القلب',
      'cardiology',
      'cardiologist',
    ],
    'العظام': [
      'العظام',
      'عظام',
      'طب العظام',
      'جراحة العظام',
      'orthopedics',
      'orthopaedics',
      'orthopedic',
      'orthopaedic',
    ],
    'الباطنية': [
      'الباطنيه',
      'باطنيه',
      'الباطنه',
      'باطنه',
      'باطنية',
      'الطب الباطني',
      'الطب الباطني العام',
      'internalmedicine',
      'internist',
    ],
    'المسالك البولية': [
      'المسالك',
      'المسالك البوليه',
      'مسالك بولية',
      'طب المسالك البولية',
      'urology',
      'urologist',
    ],
  };

  for (final entry in aliases.entries) {
    if (entry.value.any(
      (alias) => normalizeDoctorSpecialty(alias) == normalized,
    )) {
      return normalizeDoctorSpecialty(entry.key);
    }
  }

  return normalized;
}

String? _doctorTextField(Map<String, dynamic> doctor, List<String> fieldNames) {
  for (final targetKey in fieldNames) {
    final normalizedTarget = targetKey.toLowerCase().replaceAll(
      RegExp(r'[_\-\s]'),
      '',
    );
    for (final entry in doctor.entries) {
      final key = entry.key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
      if (key != normalizedTarget) continue;

      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Iterable) {
        final firstValue = value
            .map((item) => item.toString().trim())
            .firstWhere((item) => item.isNotEmpty, orElse: () => '');
        if (firstValue.isNotEmpty) return firstValue;
      }
    }
  }

  return null;
}

String? doctorNameLabel(Map<String, dynamic> doctor) {
  return _doctorTextField(doctor, [
    'name',
    'fullName',
    'full_name',
    'doctorName',
    'doctor_name',
  ]);
}

String? doctorSpecialtyLabel(Map<String, dynamic> doctor) {
  return _doctorTextField(doctor, [
    'specialty',
    'speciality',
    'specialization',
    'medicalSpecialty',
    'medical_specialty',
    'category',
    'department',
    'field',
  ]);
}

bool doctorMatchesSpecialty(Map<String, dynamic> doctor, String specialty) {
  final actualSpecialty = doctorSpecialtyLabel(doctor);
  return actualSpecialty != null &&
      canonicalDoctorSpecialty(actualSpecialty) ==
          canonicalDoctorSpecialty(specialty);
}

String doctorLoadErrorMessage(Object? error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'رفضت صلاحيات Firestore قراءة مجموعة doctors. '
        'تحقق من قواعد قاعدة البيانات للمشروع '
        '${Firebase.app().options.projectId}.';
  }

  final code = error is FirebaseException ? ' (${error.code})' : '';
  return 'تعذر تحميل مجموعة doctors$code في مشروع '
      '${Firebase.app().options.projectId}. تحقق من اتصال الإنترنت وإعدادات Firebase.';
}
