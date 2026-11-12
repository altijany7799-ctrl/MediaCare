import 'package:flutter/material.dart';
import 'booking_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String name;
  final String specialty;
  final String rating;
  final Map<String, dynamic> doctorData;
  final String? doctorId;

  const DoctorDetailsScreen({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
    this.doctorData = const {},
    this.doctorId,
  });

  String _readDoctorField(List<String> keys, {String fallback = 'غير متوفر'}) {
    for (final key in keys) {
      final value = doctorData[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  Widget _buildDoctorAvatar() {
    final imageUrl = _readDoctorField(
      ['imageUrl', 'image_url', 'photoUrl', 'photo'],
      fallback: '',
    );
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.person,
        size: 70,
        color: Color(0xFF0D6E78),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Image.network(
        imageUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person,
          size: 70,
          color: Color(0xFF0D6E78),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),

        appBar: AppBar(
          title: const Text(
            'تفاصيل الطبيب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0D6E78),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D6E78),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F2F4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: _buildDoctorAvatar(),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      specialty,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '⭐ $rating',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'معلومات الطبيب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2936),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              InfoCard(
                icon: Icons.work_outline,
                title: 'الخبرة',
                value: _readDoctorField([
                  'experience',
                  'yearsOfExperience',
                  'years_experience',
                ]),
              ),

              InfoCard(
                icon: Icons.school_outlined,
                title: 'التخصص',
                value: specialty,
              ),

              InfoCard(
                icon: Icons.location_on_outlined,
                title: 'الموقع',
                value: _readDoctorField([
                  'location',
                  'clinic',
                  'address',
                  'hospital',
                ]),
              ),

              InfoCard(
                icon: Icons.access_time,
                title: 'ساعات العمل',
                value: _readDoctorField([
                  'workingHours',
                  'working_hours',
                  'hours',
                ]),
              ),

              const SizedBox(height: 25),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'عن الطبيب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2936),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  _readDoctorField([
                    'about',
                    'bio',
                    'description',
                  ], fallback: 'لا توجد نبذة تعريفية عن الطبيب.'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            doctorName: name,
                            specialty: specialty,
                            doctorId: doctorId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'حجز موعد',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE2F2F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0D6E78)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
