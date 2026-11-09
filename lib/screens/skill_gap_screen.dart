
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'learning_roadmap_screen.dart';

class SkillGapScreen extends StatefulWidget {
  final List<String> skills;

  const SkillGapScreen({
    super.key,
    required this.skills,
  });

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  static const Color primary = Color(0xFF6855D9);
  static const Color background = Color(0xFFF7F7FC);

  final List<String> roles = [
    'AI/ML Engineer',
    'Data Scientist',
    'Data Analyst',
    'Flutter Developer',
    'Cybersecurity Engineer',
  ];

  String selectedRole = 'AI/ML Engineer';

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? result;

  Future<void> analyzeSkills() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      result = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/analyze-skill-gap'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skills': widget.skills,
          'target_role': selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['error'] == null) {
        setState(() {
          result = data;
        });
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Unable to analyze skills.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Could not connect to the server. Make sure your backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Skill Gap Analyzer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF24213D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover your skill gaps',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24213D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Compare your current skills with the skills required '
                  'for your dream career.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSelectionCard(),

                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],

                if (result != null) ...[
                  const SizedBox(height: 24),
                  _buildResults(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your target career',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF24213D),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedRole,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: roles.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: isLoading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                        result = null;
                        errorMessage = null;
                      });
                    }
                  },
          ),
          const SizedBox(height: 18),
          Text(
            '${widget.skills.length} skills detected from your resume',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isLoading || widget.skills.isEmpty
                  ? null
                  : analyzeSkills,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(
                isLoading ? 'Analyzing...' : 'Analyze Skill Gap',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (widget.skills.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'No resume skills were provided. Analyze a resume first.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final int percentage =
        (result!['match_percentage'] as num).toInt();

    final matched =
        List<String>.from(result!['matched_skills'] ?? []);
    final missing =
        List<String>.from(result!['missing_skills'] ?? []);
    final high =
        List<String>.from(result!['high_priority'] ?? []);
    final medium =
        List<String>.from(result!['medium_priority'] ?? []);
    final low =
        List<String>.from(result!['low_priority'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreCard(percentage, matched.length, missing.length),
        const SizedBox(height: 20),

        _buildSkillCard(
          'Your matching skills',
          'Skills you already have',
          matched,
          const Color(0xFF16865B),
          const Color(0xFFE8F7F0),
          Icons.check_circle_outline,
        ),

        const SizedBox(height: 16),

        _buildPriorityCard(
          'High priority',
          'Focus on these skills first',
          high,
          const Color(0xFFD94A4A),
          const Color(0xFFFFEEEE),
        ),

        const SizedBox(height: 16),

        _buildPriorityCard(
          'Medium priority',
          'Build these skills next',
          medium,
          const Color(0xFFB7791F),
          const Color(0xFFFFF5DF),
        ),

        const SizedBox(height: 16),

        _buildPriorityCard(
          'Low priority',
          'Additional skills to strengthen your profile',
          low,
          const Color(0xFF5264B5),
          const Color(0xFFEEF0FF),
        ),

        const SizedBox(height: 16),

        _buildSkillCard(
          'All missing skills',
          'Skills not detected in your resume',
          missing,
          const Color(0xFFD94A4A),
          const Color(0xFFFFEEEE),
          Icons.flag_outlined,
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6855D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LearningRoadmapScreen(
                  skills: widget.skills,
                  targetRole: selectedRole,
                ),
              ));
            },
            icon: const Icon(Icons.route_outlined),
            label: const Text('Generate My Learning Roadmap'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your match percentage is based on the number of required '
          'skills detected in your resume. It is an indicative '
          'comparison, not a hiring probability.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(int percentage, int matched, int missing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6855D9),
            Color(0xFF8976EF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your career skill match',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Target role: $selectedRole',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _scoreMetric('$matched', 'Matched'),
              const SizedBox(width: 28),
              _scoreMetric('$missing', 'Missing'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillCard(
    String title,
    String subtitle,
    List<String> skills,
    Color color,
    Color lightColor,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24213D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            const Text(
              'None found.',
              style: TextStyle(color: Colors.black54),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(
    String title,
    String subtitle,
    List<String> skills,
    Color color,
    Color lightColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24213D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            const Text(
              'No skills in this priority group.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...skills.map((skill) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Learn',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
