import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/doctor_catalog.dart';
import 'doctor_details_screen.dart';

class DoctorsScreen extends StatelessWidget {
  final String specialty;

  const DoctorsScreen({super.key, required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('أطباء $specialty'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  doctorLoadErrorMessage(snapshot.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final firestoreDocuments = snapshot.data?.docs ?? [];
          final firestoreDoctors = firestoreDocuments.map((document) {
            return <String, dynamic>{
              ...document.data(),
              '_firestoreDocumentId': document.id,
            };
          }).toList();
          final firestoreMatches = firestoreDoctors
              .where((data) => doctorMatchesSpecialty(data, specialty))
              .toList();
          final useSamples = firestoreDocuments.isEmpty;
          final matchingDoctors = useSamples
              ? sampleDoctors
                    .where((data) => doctorMatchesSpecialty(data, specialty))
                    .toList()
              : firestoreMatches;

          if (matchingDoctors.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد أطباء لهذا التخصص حاليًا',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (useSamples)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    sampleDoctorsNotice,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ...matchingDoctors.map((doctor) {
                  final name = doctorNameLabel(doctor) ?? 'طبيب';
                final doctorSpecialty =
                    doctorSpecialtyLabel(doctor) ?? specialty;
                final ratingValue = doctor['rating'];
                final rating = ratingValue is num
                    ? ratingValue.toDouble()
                    : double.tryParse(ratingValue?.toString() ?? '') ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(
                            name: name,
                            specialty: doctorSpecialty,
                            rating: rating.toStringAsFixed(1),
                            doctorData: doctor,
                            doctorId: doctor['_firestoreDocumentId']
                                ?.toString(),
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      child: Icon(Icons.medical_services),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(doctorSpecialty),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
