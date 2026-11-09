
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InterviewPrepScreen extends StatefulWidget {
  final List<String> skills;

  const InterviewPrepScreen({
    super.key,
    required this.skills,
  });

  @override
  State<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState
    extends State<InterviewPrepScreen> {
  static const List<String> roles = [
    'AI/ML Engineer',
    'Data Scientist',
    'Data Analyst',
    'Flutter Developer',
    'Cybersecurity Engineer',
  ];

  String role = roles.first;
  String type = 'Technical';

  bool loading = false;

  String? error;

  List<dynamic> questions = [];

  final Map<int, TextEditingController> answers = {};

  Map<String, dynamic>? evaluation;

  // Generate interview questions
  Future<void> loadQuestions() async {
    setState(() {
      loading = true;
      error = null;
      evaluation = null;
      questions = [];

      for (final controller in answers.values) {
        controller.dispose();
      }

      answers.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/interview/questions',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'target_role': role,
          'question_type': type,
          'skills': widget.skills,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['detail'] ?? 'Unable to load questions',
        );
      }

      final loadedQuestions =
          List<dynamic>.from(data['questions'] ?? []);

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;

        for (int i = 0; i < questions.length; i++) {
          answers[i] = TextEditingController();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Could not load interview questions. Check that the backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Evaluate submitted answers
  Future<void> evaluate() async {
    final submitted = <Map<String, String>>[];

    for (int i = 0; i < questions.length; i++) {
      submitted.add({
        'question':
            questions[i]['question']?.toString() ?? '',
        'answer': answers[i]?.text ?? '',
      });
    }

    if (submitted.any(
      (item) => item['answer']!.trim().isEmpty,
    )) {
      setState(() {
        error = 'Please answer all questions before evaluating.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      evaluation = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/interview/evaluate',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'target_role': role,
          'answers': submitted,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception('Evaluation failed');
      }

      if (!mounted) return;

      setState(() {
        evaluation = Map<String, dynamic>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Could not evaluate answers. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in answers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Preparation'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          // Heading
          const Text(
            'Practice with purpose',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose a role and question category, '
            'write your answers, then get structured practice feedback.',
          ),

          const SizedBox(height: 20),

          // Role selection
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(
              labelText: 'Target role',
              border: OutlineInputBorder(),
            ),
            items: roles.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text(r),
              );
            }).toList(),
            onChanged: loading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        role = value;
                      });
                    }
                  },
          ),

          const SizedBox(height: 12),

          // Question category
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(
              labelText: 'Question category',
              border: OutlineInputBorder(),
            ),
            items: ['Technical', 'HR'].map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text(r),
              );
            }).toList(),
            onChanged: loading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        type = value;
                      });
                    }
                  },
          ),

          const SizedBox(height: 16),

          // Generate questions button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : loadQuestions,
              icon: const Icon(Icons.quiz_outlined),
              label: const Text(
                'Generate practice questions',
              ),
            ),
          ),

          // Loading indicator
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error message
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),

          // Generated questions
          ...List.generate(
            questions.length,
            (i) {
              return Card(
                margin: const EdgeInsets.only(top: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Question ${i + 1}',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        questions[i]['question'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: answers[i],
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Write your answer here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Evaluate answers button
          if (questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : evaluate,
                  icon: const Icon(
                    Icons.rate_review_outlined,
                  ),
                  label: const Text(
                    'Evaluate my answers',
                  ),
                ),
              ),
            ),

          // Evaluation results
          if (evaluation != null)
            Card(
              margin: const EdgeInsets.only(top: 20),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Practice score: '
                      '${evaluation!['score']}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      evaluation!['summary'] ?? '',
                    ),

                    const SizedBox(height: 12),

                    ...(evaluation!['feedback'] as List? ?? [])
                        .map(
                      (feedback) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text('• $feedback'),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'This is rule-based practice feedback, '
                      'not an expert hiring assessment.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}