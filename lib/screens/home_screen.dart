import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:check_in_point/providers/auth_provider.dart';

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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 72),
            const SizedBox(height: 12),
            Text('Signed in as ${userEmail ?? 'Anonymous'}'),
          ],
        ),
      ),
    );
  }
}


