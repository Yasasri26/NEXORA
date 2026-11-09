import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JobMatchingScreen extends StatefulWidget {
  final List<String> skills;
  const JobMatchingScreen({super.key, required this.skills});
  @override
  State<JobMatchingScreen> createState() => _JobMatchingScreenState();
}

class _JobMatchingScreenState extends State<JobMatchingScreen> {
  static const roles = ['AI/ML Engineer', 'Data Scientist', 'Data Analyst', 'Flutter Developer', 'Cybersecurity Engineer'];
  String role = roles.first;
  bool loading = false;
  String? error;
  List jobs = [];

  Future<void> findJobs() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await http.post(Uri.parse('http://127.0.0.1:8000/match-jobs'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'skills': widget.skills, 'target_role': role}));
      final data = jsonDecode(response.body);
      if (response.statusCode != 200) throw Exception(data['detail'] ?? 'Unable to match jobs');
      setState(() => jobs = data['jobs'] ?? []);
    } catch (e) { setState(() => error = 'Could not load matches. Check that the NEXORA backend is running.'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  void initState() { super.initState(); findJobs(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Job Matching')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Find roles that fit your profile', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Matches are estimated from your detected skills against sample role requirements. Current skills: ${widget.skills.isEmpty ? 'None detected yet — upload a resume first.' : widget.skills.join(', ')}'),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Target role', border: OutlineInputBorder()), items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) { if (v != null) setState(() => role = v); }),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: loading ? null : findJobs, icon: const Icon(Icons.search), label: const Text('Find matching roles')),
      if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
      if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      ...jobs.map((job) => Card(margin: const EdgeInsets.only(top: 14), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(job['title'] ?? 'Role', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), Chip(label: Text('${job['match_percentage']}% match'))]),
        Text('${job['company']} • ${job['location']}'), const SizedBox(height: 8), Text(job['description'] ?? ''),
        const SizedBox(height: 10), const Text('Skills to highlight', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: (job['matched_skills'] as List? ?? []).map((s) => Chip(label: Text('$s'))).toList()),
        if ((job['missing_skills'] as List? ?? []).isNotEmpty) Text('Consider learning: ${(job['missing_skills'] as List).join(', ')}', style: const TextStyle(color: Colors.deepOrange)),
      ])))).toList(),
      const SizedBox(height: 12), const Text('Note: These are illustrative sample opportunities, not live vacancies. Verify openings on official employer career pages.', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );
}
