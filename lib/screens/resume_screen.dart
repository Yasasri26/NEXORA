import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'skill_gap_screen.dart';

class ResumeScreen extends StatefulWidget {
  final ValueChanged<List<String>>? onSkillsDetected;
  const ResumeScreen({super.key, this.onSkillsDetected});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  PlatformFile? selectedFile;
  int selectedFileSize = 0;

  bool isLoading = false;

  Map<String, dynamic>? analysisResult;

  final Color primary = const Color(0xFF6855D9);
  final Color dark = const Color(0xFF24213D);
  final Color background = const Color(0xFFF7F7FC);

  final List<String> allSections = [
    'Education',
    'Experience',
    'Projects',
    'Skills',
    'Certifications',
  ];

  // ---------------- SELECT RESUME ----------------

  Future<void> pickResume() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      if (bytes.length > 10 * 1024 * 1024) {
        showMessage('Please select a PDF smaller than 10 MB.');
        return;
      }

      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        showMessage('Please select a valid PDF file.');
        return;
      }

      setState(() {
        selectedFile = file;
        selectedFileSize = bytes.length;
        analysisResult = null;
      });

      showMessage('Resume uploaded successfully!');
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to select file: $e');
    }
  }

  // ---------------- NOTIFICATIONS ----------------

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- REMOVE RESUME ----------------

  void removeResume() {
    setState(() {
      selectedFile = null;
      selectedFileSize = 0;
      analysisResult = null;
    });
  }

  // ---------------- FILE SIZE ----------------

  String formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ---------------- API INTEGRATION ----------------

  Future<void> analyzeResume() async {
    if (selectedFile == null) return;

    setState(() {
      isLoading = true;
      analysisResult = null;
    });

    try {
      final bytes = await selectedFile!.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://nexora-v0ex.onrender.com/analyze-resume'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: selectedFile!.name,
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result =
            jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          analysisResult = result;
        });
        widget.onSkillsDetected?.call(List<String>.from(result['skills'] ?? []));

        showMessage('Resume analysis completed!');
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------- RESULT DATA ----------------

  List<String> get skills {
    return List<String>.from(
      analysisResult?['skills'] ?? [],
    );
  }

  List<String> get sections {
    return List<String>.from(
      analysisResult?['sections_found'] ?? [],
    );
  }

  List<String> get missingSections {
    return allSections.where((section) {
      return !sections.any(
        (item) => item.toLowerCase() == section.toLowerCase(),
      );
    }).toList();
  }

  int get wordCount {
    return (analysisResult?['word_count'] as num?)?.toInt() ?? 0;
  }

  int get pageCount {
    return (analysisResult?['page_count'] as num?)?.toInt() ?? 0;
  }

  int get resumeScore {
    return ((analysisResult?['resume_score'] as num?)?.toInt() ?? 0)
        .clamp(0, 100)
        .toInt();
  }

  // ---------------- SUGGESTIONS ----------------

  List<String> get suggestions {
    final List<String> tips = [];

    for (final section in missingSections) {
      tips.add(
        'Consider adding a $section section if it is relevant to your profile.',
      );
    }

    if (wordCount < 150) {
      tips.add(
        'Your resume has limited content. Add relevant projects, experience and achievements.',
      );
    }

    if (skills.length < 5) {
      tips.add(
        'Include more relevant technical skills that you can demonstrate.',
      );
    }

    if (tips.isEmpty) {
      tips.add(
        'Your main resume sections were detected. Improve your bullet points with measurable achievements.',
      );

      tips.add(
        'Tailor your skills and project descriptions to the role you are targeting.',
      );
    }

    return tips;
  }

  // ---------------- STRENGTHS ----------------

  List<String> get strengths {
    final List<String> items = [];

    if (skills.length >= 5) {
      items.add('A good range of matching skills was detected.');
    }

    if (sections.contains('Projects')) {
      items.add('A Projects section was detected.');
    }

    if (sections.contains('Education')) {
      items.add('An Education section was detected.');
    }

    if (sections.contains('Experience')) {
      items.add('An Experience section was detected.');
    }

    if (items.isEmpty) {
      items.add(
        'Your resume has been successfully processed. Build out your sections to provide more career information.',
      );
    }

    return items;
  }

  // ---------------- OPEN SKILL GAP ANALYZER ----------------

  void openSkillGapAnalyzer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillGapScreen(
          skills: skills,
        ),
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pageHeader(),

                const SizedBox(height: 28),

                uploadCard(),

                if (selectedFile != null) ...[
                  const SizedBox(height: 18),

                  selectedFileCard(),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : analyzeResume,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isLoading
                            ? 'Analyzing your resume...'
                            : 'Analyze My Resume',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                if (analysisResult != null)
                  resultsDashboard()
                else if (!isLoading)
                  emptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PAGE HEADER ----------------

  Widget pageHeader() {
    return Column(
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
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NEXORA INTELLIGENCE',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            const Spacer(),

            Icon(
              Icons.auto_awesome,
              color: primary,
              size: 22,
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Resume Analyzer',
          style: TextStyle(
            color: dark,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Discover your strengths, identify skill gaps and improve your professional profile.',
          style: TextStyle(
            color: Color(0xFF77758A),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ---------------- UPLOAD CARD ----------------

  Widget uploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9E7F2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24213D).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: primary,
              size: 34,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Upload your resume',
            style: TextStyle(
              color: Color(0xFF24213D),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Upload your PDF and get detailed insights into your resume.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF858398),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: isLoading ? null : pickResume,
            icon: const Icon(Icons.add),
            label: const Text('Choose PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'PDF format  •  Maximum size 10 MB',
            style: TextStyle(
              color: Color(0xFF9A98A9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SELECTED FILE ----------------

  Widget selectedFileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E7F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFE45C64),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFile!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24213D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  formatSize(selectedFileSize),
                  style: const TextStyle(
                    color: Color(0xFF858398),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: isLoading ? null : removeResume,
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFF9290A2),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9E7F2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 45,
            color: primary,
          ),

          const SizedBox(height: 13),

          const Text(
            'Your results will appear here',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF24213D),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Upload your resume and start your analysis to explore your career insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF858398),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- RESULTS DASHBOARD ----------------

  Widget resultsDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Resume Insights',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24213D),
                ),
              ),
            ),

            TextButton.icon(
              onPressed: removeResume,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('New analysis'),
            ),
          ],
        ),

        const SizedBox(height: 18),

        scoreCard(),

        const SizedBox(height: 18),

        metricGrid(),

        const SizedBox(height: 28),

        sectionTitle(
          'Skills identified',
          'Your detected skill set',
        ),

        const SizedBox(height: 13),

        skillsCard(),

        const SizedBox(height: 28),

        sectionTitle(
          'Resume completeness',
          'Sections detected in your PDF',
        ),

        const SizedBox(height: 13),

        sectionsCard(),

        const SizedBox(height: 28),

        sectionTitle(
          'Your strengths',
          'Positive indicators in your resume',
        ),

        const SizedBox(height: 13),

        strengthsCard(),

        const SizedBox(height: 28),

        sectionTitle(
          'Areas to improve',
          'Recommendations based on the current analysis',
        ),

        const SizedBox(height: 13),

        suggestionsCard(),

        const SizedBox(height: 24),

        // SKILL GAP ANALYZER BUTTON

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: openSkillGapAnalyzer,
            icon: const Icon(Icons.track_changes),
            label: const Text(
              'Analyze My Skill Gaps',
              style: TextStyle(fontWeight: FontWeight.bold),
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

        const SizedBox(height: 20),

        const Text(
          'NEXORA preliminary analysis uses rule-based scoring and keyword detection. It is not an official ATS score or a complete evaluation of resume quality.',
          style: TextStyle(
            color: Color(0xFF858398),
            fontSize: 11,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ---------------- SCORE CARD ----------------

  Widget scoreCard() {
    final score = resumeScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6553D5),
            Color(0xFF8978E8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.19),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;

          final scoreVisual = SizedBox(
            width: 145,
            height: 145,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      'OUT OF 100',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final scoreDescription = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Resume Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                score >= 75
                    ? 'Your resume has a good foundation.'
                    : score >= 50
                        ? 'Your resume has room for improvement.'
                        : 'Your resume needs further development.',
                textAlign:
                    compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Based on detected skills, resume sections and content length.',
                textAlign:
                    compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                scoreVisual,
                const SizedBox(height: 15),
                scoreDescription,
              ],
            );
          }

          return Row(
            children: [
              scoreVisual,
              const SizedBox(width: 25),
              Expanded(child: scoreDescription),
            ],
          );
        },
      ),
    );
  }

  // ---------------- METRIC GRID ----------------

  Widget metricGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 650 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            metricCard(
              'Skills detected',
              '${skills.length}',
              Icons.psychology_outlined,
              const Color(0xFF6553D5),
            ),

            metricCard(
              'Word count',
              '$wordCount',
              Icons.article_outlined,
              const Color(0xFF279A87),
            ),

            metricCard(
              'Pages',
              '$pageCount',
              Icons.description_outlined,
              const Color(0xFFDF9844),
            ),

            metricCard(
              'Sections',
              '${sections.length}/${allSections.length}',
              Icons.checklist_outlined,
              const Color(0xFF477FC8),
            ),
          ],
        );
      },
    );
  }

  // ---------------- METRIC CARD ----------------

  Widget metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEAE8F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF24213D),
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF858398),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------

  Widget sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF24213D),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF858398),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ---------------- SKILLS CARD ----------------

  Widget skillsCard() {
    return contentCard(
      child: skills.isEmpty
          ? const Text('No matching skills were detected.')
          : Wrap(
              spacing: 9,
              runSpacing: 10,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ---------------- SECTIONS CARD ----------------

  Widget sectionsCard() {
    return contentCard(
      child: Column(
        children: allSections.map((section) {
          final found = sections.any(
            (item) => item.toLowerCase() == section.toLowerCase(),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Icon(
                  found
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: found
                      ? const Color(0xFF299D79)
                      : const Color(0xFFB5B3C2),
                  size: 20,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    section,
                    style: const TextStyle(
                      color: Color(0xFF39364D),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),

                Text(
                  found ? 'Detected' : 'Not detected',
                  style: TextStyle(
                    color: found
                        ? const Color(0xFF299D79)
                        : const Color(0xFF9693A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- STRENGTHS CARD ----------------

  Widget strengthsCard() {
    return contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: strengths.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF299D79),
                  size: 19,
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF49465B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- SUGGESTIONS CARD ----------------

  Widget suggestionsCard() {
    return contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestions.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFD99535),
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF49465B),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- REUSABLE CARD ----------------

  Widget contentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAE8F2),
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}