import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:check_in_point/providers/auth_provider.dart';
import 'package:check_in_point/screens/check_in_create_screen.dart';
import 'package:check_in_point/screens/check_in_view_screen.dart';
import 'package:provider/provider.dart';
import 'package:check_in_point/providers/check_in_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = context.select<AuthProvider, String?>(
      (p) => p.user?.email,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Point'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, checkInProvider, _) {
          final active = checkInProvider.activePoint;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Signed in'),
                  subtitle: Text(userEmail ?? 'Anonymous'),
                ),
              ),
              const SizedBox(height: 12),
              if (active != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: const Text('Active check-in'),
                    subtitle: Text(
                        'Lat: ${active.latitude.toStringAsFixed(5)}, Lng: ${active.longitude.toStringAsFixed(5)}\nRadius: ${active.radiusMeters} m'),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'View',
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckInViewScreen()),
                        );
                      },
                    ),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('No active check-in'),
                    subtitle: const Text('Create one to get started'),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_location_alt_outlined),
                      title: const Text('Create check-in'),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckInCreateScreen()),
                        );
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: const Text('View active check-in'),
                      enabled: active != null,
                      onTap: active == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CheckInViewScreen()),
                              );
                            },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Clear active check-in'),
                      enabled: active != null,
                      onTap: active == null
                          ? null
                          : () async {
                              await context.read<CheckInProvider>().clearActive();
                            },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   icon: const Icon(Icons.add_location_alt_outlined),
      //   label: const Text('Create check-in'),
      //   onPressed: () async {
      //     await Navigator.of(context).push(
      //       MaterialPageRoute(builder: (_) => const CheckInCreateScreen()),
      //     );
      //   },
      // ),
    );
  }
}


