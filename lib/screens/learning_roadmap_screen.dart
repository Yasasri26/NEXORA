import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LearningRoadmapScreen extends StatefulWidget {
  final List<String> skills;
  final String targetRole;

  const LearningRoadmapScreen({
    super.key,
    required this.skills,
    required this.targetRole,
  });

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  static const purple = Color(0xFF6855D9);

  Map<String, dynamic>? roadmap;
  bool loading = false;
  String? error;

  final Set<String> completed = {};

  @override
  void initState() {
    super.initState();
    generate();
  }

  Future<void> generate() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://nexora-v0ex.onrender.com/generate-roadmap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'skills': widget.skills,
          'target_role': widget.targetRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['weekly_plan'] != null) {
        if (!mounted) return;

        setState(() {
          roadmap = data;
          completed.clear();
        });
      } else {
        throw Exception(data is Map ? data['detail'] ?? data['error'] : null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error =
              'Could not generate roadmap. Check that your backend is running.\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = (roadmap?['weekly_plan'] as List?) ?? [];

    final totalTopics = weeks.fold<int>(
      0,
      (sum, week) => sum + ((week['topics'] as List?)?.length ?? 0),
    );

    final progress = totalTopics == 0
        ? 0.0
        : (completed.length / totalTopics).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        title: const Text(
          'Learning Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF7F7FC),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : error != null
          ? _buildError()
          : roadmap == null
          ? const Center(child: Text('No roadmap available.'))
          : _buildRoadmap(weeks, totalTopics, progress),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: generate, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmap(List weeks, int totalTopics, double progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(totalTopics, progress),
              const SizedBox(height: 24),
              const Text(
                'Your weekly learning plan',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24213D),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete each topic as you learn. '
                'Your progress updates automatically.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),

              if (weeks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Your resume already covers all the skills '
                    'in this role. Keep building projects and '
                    'deepening your expertise!',
                  ),
                ),

              ...weeks.map((week) => _buildWeekCard(week)),

              const SizedBox(height: 8),
              const Text(
                'Tip: Build and publish projects alongside '
                'your learning to demonstrate these skills '
                'in your portfolio.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalTopics, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [purple, Color(0xFF9181EF)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PERSONAL LEARNING PLAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.targetRole,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${roadmap!['total_weeks']} weeks • '
            '$totalTopics topics to learn',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your progress',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(dynamic week) {
    final topics = (week['topics'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'WEEK ${week['week']}',
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  week['title'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...topics.map((topic) {
            final skill = topic['skill'].toString();

            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: purple,
              value: completed.contains(skill),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    completed.add(skill);
                  } else {
                    completed.remove(skill);
                  }
                });
              },
              title: Text(
                skill,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(topic['topic'].toString()),
            );
          }),

          const Divider(),
          const Text(
            'PRACTICAL PROJECT',
            style: TextStyle(
              color: purple,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            week['project'].toString(),
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
