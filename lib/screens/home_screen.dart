import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/doctor_catalog.dart';
import 'booking_screen.dart';
import 'doctor_details_screen.dart';
import 'doctors_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: const [HomePage(), AppointmentsScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF0D6E78),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'مواعيدي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, dynamic>> specialties = [
    {
      'title': 'الأسنان',
      'icon': Icons.medical_services,
      'specialty': 'الأسنان',
    },
    {'title': 'العيون', 'icon': Icons.visibility, 'specialty': 'العيون'},
    {'title': 'القلب', 'icon': Icons.favorite, 'specialty': 'القلب'},
    {'title': 'العظام', 'icon': Icons.accessibility_new, 'specialty': 'العظام'},
    {
      'title': 'الباطنية',
      'icon': Icons.local_hospital,
      'specialty': 'الباطنية',
    },
    {
      'title': 'المسالك',
      'icon': Icons.water_drop,
      'specialty': 'المسالك البولية',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  List<Map<String, dynamic>> get filteredSpecialties {
    if (searchQuery.trim().isEmpty) {
      return specialties;
    }

    final query = normalize(searchQuery);

    return specialties.where((item) {
      return normalize(item['title'] as String).contains(query) ||
          normalize(item['specialty'] as String).contains(query);
    }).toList();
  }

  void openDoctors(String specialty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorsScreen(specialty: specialty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = searchQuery.trim().isNotEmpty;
    final matchingSpecialties = filteredSpecialties;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6E78),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MediCare',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا توجد إشعارات جديدة حاليًا')),
              );
            },
            icon: const Icon(Icons.notifications_none),
            tooltip: 'الإشعارات',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF0D6E78),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مرحباً بك 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اهتم بصحتك معنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'احجز موعدك مع الطبيب بسهولة وفي الوقت المناسب لك.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'ابحث عن طبيب أو تخصص',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0D6E78),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close),
                              tooltip: 'مسح البحث',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'التخصصات الطبية',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2936),
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (matchingSpecialties.isNotEmpty)
              SizedBox(
                height: 115,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: matchingSpecialties.length,
                  itemBuilder: (context, index) {
                    final item = matchingSpecialties[index];

                    return SpecialtyCard(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      specialty: item['specialty'] as String,
                    );
                  },
                ),
              )
            else if (searching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(
                  'لا توجد تخصصات مطابقة للبحث',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 25),

            if (!searching)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F2F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: Color(0xFF0D6E78),
                      size: 45,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'صحتك أولاً',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'لا تؤجل الاهتمام بصحتك.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                searching ? 'نتائج البحث عن "$searchQuery"' : 'أطباء مميزون',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2936),
                ),
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      doctorLoadErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  );
                }

                final firestoreDoctors = snapshot.data?.docs ?? [];
                final firestoreData = firestoreDoctors.map((document) {
                  return <String, dynamic>{
                    ...document.data(),
                    '_firestoreDocumentId': document.id,
                  };
                }).toList();
                final doctors = firestoreData.isEmpty
                    ? sampleDoctors
                    : firestoreData;
                final query = normalize(searchQuery);
                final matchingDoctors = doctors.where((data) {
                  if (!searching) return true;

                  final name = doctorNameLabel(data) ?? '';
                  final doctorSpecialty =
                      doctorSpecialtyLabel(data) ?? '';
                  final category = (data['category'] ?? doctorSpecialty)
                      .toString();

                  return normalize(name).contains(query) ||
                      normalize(doctorSpecialty).contains(query) ||
                      normalize(category).contains(query);
                }).toList();

                if (matchingDoctors.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    child: Center(
                      child: Text(
                        'لم نعثر على طبيب أو تخصص مطابق',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (firestoreData.isEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: Text(
                          sampleDoctorsNotice,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ...matchingDoctors.map((data) {
                      final name = doctorNameLabel(data) ?? 'طبيب';
                      final doctorSpecialty =
                          doctorSpecialtyLabel(data) ?? 'غير محدد';
                      final category = doctorSpecialty;
                      final rating = (data['rating'] ?? '').toString();

                      return DoctorCard(
                        name: name,
                        specialty: doctorSpecialty,
                        category: category,
                        rating: rating,
                        onBook: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingScreen(
                                doctorName: name,
                                specialty: doctorSpecialty,
                                doctorId:
                                    data['_firestoreDocumentId']?.toString(),
                              ),
                            ),
                          );
                        },
                        onDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorDetailsScreen(
                                name: name,
                                specialty: doctorSpecialty,
                                rating: rating,
                                doctorData: data,
                                doctorId: data['_firestoreDocumentId']
                                    ?.toString(),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

class SpecialtyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String specialty;

  const SpecialtyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorsScreen(specialty: specialty),
          ),
        );
      },
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0D6E78), size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String category;
  final String rating;
  final VoidCallback onBook;
  final VoidCallback onDetails;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.category,
    required this.rating,
    required this.onBook,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFE2F2F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF0D6E78)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: onDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    specialty,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text('⭐ $rating', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onBook, child: const Text('حجز')),
        ],
      ),
    );
  }
}
