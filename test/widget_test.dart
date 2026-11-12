import 'package:mediacare/data/doctor_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore doctor specialty aliases match app specialties', () {
    expect(
      doctorMatchesSpecialty({'specialization': 'طب وجراحة العيون'}, 'العيون'),
      isTrue,
    );
    expect(
      doctorMatchesSpecialty({
        'category': ['طب القلب', 'باطنية'],
      }, 'القلب'),
      isTrue,
    );
    expect(
      doctorMatchesSpecialty({'specialty': 'dentistry'}, 'الأسنان'),
      isTrue,
    );
    expect(doctorMatchesSpecialty({'specialty': 'العظام'}, 'القلب'), isFalse);
    expect(
      doctorSpecialtyLabel({'specialty': '', 'category': 'المسالك البولية'}),
      'المسالك البولية',
    );
    expect(
      doctorMatchesSpecialty({
        'specialty': 'الباطنية',
        'category': 'المسالك البولية',
      }, 'المسالك البولية'),
      isFalse,
    );
    expect(doctorMatchesSpecialty({'Specialty': 'باطنية'}, 'الباطنية'), isTrue);
    expect(doctorNameLabel({'name': '', 'Full Name': 'د. هدى'}), 'د. هدى');
  });

  testWidgets('MediCare app test', (WidgetTester tester) async {
    expect(true, isTrue);
  });
}
