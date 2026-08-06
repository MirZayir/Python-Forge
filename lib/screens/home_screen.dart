// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final bool isLoading;
  final dynamic currentMission; // Preserved existing mission state

  const HomeScreen({Key? key, this.isLoading = false, this.currentMission})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Keep existing mission loading logic
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _StatWidget(label: 'Current Streak', value: '3'),
                  _StatWidget(label: 'XP', value: '1250'),
                  _StatWidget(label: 'Missions Completed', value: '12'),
                ],
              ),
              const SizedBox(height: 40),

              // Continue Learning Section
              const Text(
                'Continue Learning',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _MissionCard(mission: currentMission),
              const SizedBox(height: 40),

              // Coming Soon Section
              const Text(
                'Coming Soon',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const _DisabledFeatureCard(title: 'AI Mentor'),
              const SizedBox(height: 12),
              const _DisabledFeatureCard(title: 'Developer Journal'),
              const SizedBox(height: 12),
              const _DisabledFeatureCard(title: 'Projects'),
            ],
          ),
        ),
      ),
    );
  }
}

// Assumed existing/reusable widget implementations below

class _StatWidget extends StatelessWidget {
  final String label;
  final String value;

  const _StatWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final dynamic mission;

  const _MissionCard({this.mission});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission?.title ?? 'Mission Title',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              mission?.description ?? 'Mission description goes here.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.5, // Placeholder progress
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('50%'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledFeatureCard extends StatelessWidget {
  final String title;

  const _DisabledFeatureCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey[500]),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
