import 'package:flutter/material.dart';
import 'screens/resume_screen.dart';
import 'screens/skill_gap_screen.dart';
import 'screens/learning_roadmap_screen.dart';
import 'screens/job_matching_screen.dart';
import 'screens/interview_prep_screen.dart';

void main() => runApp(const NexoraApp());

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key});
  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> {
  bool isDark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NEXORA',
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6855D9), scaffoldBackgroundColor: const Color(0xFFF7F7FC)),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF9286F2)),
    home: NexoraHome(isDark: isDark, onThemeChanged: () => setState(() => isDark = !isDark)),
  );
}

class NexoraHome extends StatefulWidget {
  const NexoraHome({super.key, required this.isDark, required this.onThemeChanged});
  final bool isDark;
  final VoidCallback onThemeChanged;
  @override
  State<NexoraHome> createState() => _NexoraHomeState();
}

class _NexoraHomeState extends State<NexoraHome> {
  int selectedIndex = 0;
  List<String> skills = [];
  String targetRole = 'AI/ML Engineer';
  String profileName = 'NEXORA User';
  late final TextEditingController profileNameController;
  late final TextEditingController skillController;
  final roles = const ['AI/ML Engineer', 'Data Scientist', 'Data Analyst', 'Flutter Developer', 'Cybersecurity Engineer'];
  final pages = const [
    _NavItem('Dashboard', Icons.dashboard_outlined),
    _NavItem('My Resume', Icons.description_outlined),
    _NavItem('Job Matching', Icons.work_outline),
    _NavItem('Skill Analysis', Icons.analytics_outlined),
    _NavItem('Learning Roadmap', Icons.route_outlined),
    _NavItem('Interview Prep', Icons.forum_outlined),
    _NavItem('My Profile', Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    profileNameController = TextEditingController();
    skillController = TextEditingController();
  }

  @override
  void dispose() {
    profileNameController.dispose();
    skillController.dispose();
    super.dispose();
  }

  void navigate(int index) {
    setState(() => selectedIndex = index);
    if (MediaQuery.of(context).size.width < 850 && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 850;
    return Scaffold(
      drawer: wide ? null : Drawer(child: buildSidebar()),
      body: Row(children: [if (wide) buildSidebar(), Expanded(child: Column(children: [buildTopBar(wide), Expanded(child: buildPage())]))]),
    );
  }

  Widget buildPage() {
    switch (selectedIndex) {
      case 0: return buildDashboard();
      case 1: return ResumeScreen(onSkillsDetected: (value) => setState(() { for (final skill in value) { if (!skills.any((s) => s.toLowerCase() == skill.toLowerCase())) skills.add(skill); } }));
      case 2: return JobMatchingScreen(skills: skills);
      case 3: return SkillGapScreen(skills: skills);
      case 4: return LearningRoadmapScreen(skills: skills, targetRole: targetRole);
      case 5: return InterviewPrepScreen(skills: skills);
      case 6: return buildProfile();
      default: return buildDashboard();
    }
  }

  Widget buildSidebar() => Container(
    width: 250, padding: const EdgeInsets.all(18), color: Theme.of(context).colorScheme.surface,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12), Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6855D9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome, color: Colors.white)), const SizedBox(width: 10), const Text('NEXORA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5))]),
      const SizedBox(height: 8), const Text('Your next opportunity.', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 32),
      const Text('WORKSPACE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      ...List.generate(pages.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 5), child: ListTile(dense: true, selected: selectedIndex == i, selectedTileColor: Theme.of(context).colorScheme.primaryContainer, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: Icon(pages[i].icon), title: Text(pages[i].title, style: const TextStyle(fontSize: 13)), onTap: () => navigate(i)))),
      const Spacer(), const Text('NEXORA AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8), const Text('Your skills. Your potential. Your next opportunity.', style: TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  );

  Widget buildTopBar(bool wide) => Container(height: 70, padding: const EdgeInsets.symmetric(horizontal: 22), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))), child: Row(children: [if (!wide) Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())), const Spacer(), IconButton(onPressed: widget.onThemeChanged, icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode_outlined)), const SizedBox(width: 10), CircleAvatar(child: Text(profileName.isEmpty ? 'N' : profileName[0].toUpperCase()))]));

  Widget buildDashboard() => SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('WELCOME TO NEXORA 👋', style: TextStyle(color: Color(0xFF6855D9), fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('Your career journey starts here.', style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Understand your strengths, close skill gaps and prepare for your next opportunity.'), const SizedBox(height: 25),
    LayoutBuilder(builder: (context, c) { final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 550 ? 2 : 1; return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: cols == 1 ? 3.2 : 1.65, children: [StatCard(title: 'Resume skills', value: '${skills.length}', icon: Icons.psychology_outlined), StatCard(title: 'Target role', value: targetRole, icon: Icons.work_outline), StatCard(title: 'Career modules', value: '6', icon: Icons.dashboard_customize_outlined), StatCard(title: 'Profile', value: profileName == 'NEXORA User' ? 'Set up' : 'Ready', icon: Icons.person_outline)]); }),
    const SizedBox(height: 25), Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Your NEXORA workspace', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Complete these steps to get the most from your career dashboard.'), const SizedBox(height: 18), _actionRow('01', 'Analyze your resume', 'Upload a PDF and extract your current skills.', 1), _actionRow('02', 'Explore job matches', 'Compare your profile with sample role requirements.', 2), _actionRow('03', 'Find your skill gaps', 'See which capabilities to build next.', 3), _actionRow('04', 'Generate a learning roadmap', 'Turn missing skills into a weekly plan.', 4), _actionRow('05', 'Practice interviews', 'Prepare technical and HR answers.', 5)]))),
    const SizedBox(height: 22), Container(width: double.infinity, padding: const EdgeInsets.all(26), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF6558D3), Color(0xFF9286F2)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your skills. Your potential.\nYour next opportunity.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Build your next career move with confidence.', style: TextStyle(color: Colors.white70))])),
  ]));

  Widget _actionRow(String number, String title, String subtitle, int page) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(number, style: const TextStyle(fontSize: 11))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.arrow_forward_ios, size: 15), onTap: () => navigate(page));

  Widget buildProfile() {
    profileNameController.text = profileName == 'NEXORA User' ? profileNameController.text : profileName;
    return StatefulBuilder(builder: (context, refresh) => ListView(padding: const EdgeInsets.all(28), children: [
      const Text('My Profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Manage your career preferences and skills used across NEXORA.'), const SizedBox(height: 22),
      TextField(controller: profileNameController, decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 16),
      DropdownButtonFormField<String>(value: targetRole, decoration: const InputDecoration(labelText: 'Target career role', border: OutlineInputBorder()), items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) { if (v != null) setState(() => targetRole = v); }), const SizedBox(height: 22),
      const Text('Your skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 8), Text('Resume-detected skills are added automatically. You can also add skills manually.'), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: skillController, decoration: const InputDecoration(hintText: 'e.g. Python, SQL, Docker', border: OutlineInputBorder()), onSubmitted: (_) { final v = skillController.text.trim(); if (v.isNotEmpty && !skills.any((s) => s.toLowerCase() == v.toLowerCase())) setState(() => skills.add(v)); skillController.clear(); refresh(() {}); })), const SizedBox(width: 8), IconButton.filled(onPressed: () { final v = skillController.text.trim(); if (v.isNotEmpty && !skills.any((s) => s.toLowerCase() == v.toLowerCase())) setState(() => skills.add(v)); skillController.clear(); refresh(() {}); }, icon: const Icon(Icons.add))]),
      const SizedBox(height: 10), Wrap(spacing: 7, children: skills.map((s) => InputChip(label: Text(s), onDeleted: () { setState(() => skills.remove(s)); refresh(() {}); })).toList()), const SizedBox(height: 24), FilledButton.icon(onPressed: () { setState(() => profileName = profileNameController.text.trim().isEmpty ? 'NEXORA User' : profileNameController.text.trim()); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated for this session.'))); }, icon: const Icon(Icons.save_outlined), label: const Text('Save profile')), const SizedBox(height: 12), const Text('Profile edits currently remain in app memory for this session. Add persistent sign-in/storage before deploying to real users.', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]));
  }
}

class _NavItem { const _NavItem(this.title, this.icon); final String title; final IconData icon; }

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, required this.icon});
  final String title, value; final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: Colors.grey))])));
}
