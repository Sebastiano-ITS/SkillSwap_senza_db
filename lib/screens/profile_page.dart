import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: firestoreService.streamUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore: ${snapshot.error}'),
            );
          }

          final userProfile = snapshot.data;
          if (userProfile == null) {
            return const Center(
              child: Text('Profilo non trovato'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userProfile.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tariffa oraria: €${userProfile.hourlyRate.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (userProfile.canTeach.isNotEmpty) ...[
                  Text(
                    'Può insegnare:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: userProfile.canTeach
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (userProfile.wantsToLearn.isNotEmpty) ...[
                  Text(
                    'Vuole imparare:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: userProfile.wantsToLearn
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
