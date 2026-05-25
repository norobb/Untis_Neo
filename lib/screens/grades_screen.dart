import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GradeEntry {
  final String id;
  final double value;
  final double weight; // 1.0 for normal, 2.0 for exams etc.
  final String label;

  GradeEntry({
    required this.id,
    required this.value,
    required this.weight,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'weight': weight,
        'label': label,
      };

  factory GradeEntry.fromJson(Map<String, dynamic> json) => GradeEntry(
        id: json['id'],
        value: (json['value'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        label: json['label'],
      );
}

class SubjectGrades {
  final String subjectName;
  final List<GradeEntry> grades;

  SubjectGrades({required this.subjectName, required this.grades});

  double get average {
    if (grades.isEmpty) return 0.0;
    double totalWeight = 0;
    double totalSum = 0;
    for (var g in grades) {
      totalSum += g.value * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight == 0 ? 0 : totalSum / totalWeight;
  }

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'grades': grades.map((g) => g.toJson()).toList(),
      };

  factory SubjectGrades.fromJson(Map<String, dynamic> json) => SubjectGrades(
        subjectName: json['subjectName'],
        grades: (json['grades'] as List)
            .map((g) => GradeEntry.fromJson(g))
            .toList(),
      );
}

class GradesScreen extends StatefulWidget {
  const GradesScreen({Key? key}) : super(key: key);

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<SubjectGrades> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('grades_data');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _subjects = decoded.map((e) => SubjectGrades.fromJson(e)).toList();
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_subjects.map((e) => e.toJson()).toList());
    await prefs.setString('grades_data', data);
  }

  double get _totalAverage {
    if (_subjects.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (var s in _subjects) {
      if (s.grades.isNotEmpty) {
        sum += s.average;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  void _addSubject() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neues Fach'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Fachname'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _subjects.add(SubjectGrades(
                      subjectName: controller.text.trim(), grades: []));
                });
                _saveGrades();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _addGrade(SubjectGrades subject) {
    final TextEditingController valueCtrl = TextEditingController();
    final TextEditingController labelCtrl = TextEditingController();
    final TextEditingController weightCtrl = TextEditingController(text: "1.0");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note für ${subject.subjectName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Note (z.B. 1.0 oder 15)'),
            ),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Gewichtung (z.B. 1.0 oder 2.0 für Klausur)'),
            ),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Bezeichnung (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(valueCtrl.text.replaceAll(',', '.'));
              final w = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
              if (val != null && w != null) {
                setState(() {
                  subject.grades.add(GradeEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    value: val,
                    weight: w,
                    label: labelCtrl.text.trim().isEmpty ? 'Note' : labelCtrl.text.trim(),
                  ));
                });
                _saveGrades();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _deleteSubject(SubjectGrades subject) {
    setState(() {
      _subjects.remove(subject);
    });
    _saveGrades();
  }

  void _deleteGrade(SubjectGrades subject, GradeEntry grade) {
    setState(() {
      subject.grades.remove(grade);
    });
    _saveGrades();
  }

  Widget _buildGlassCard({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Notenrechner',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSubject,
            tooltip: 'Fach hinzufügen',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Gesamtschnitt',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _totalAverage.toStringAsFixed(2),
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _subjects.isEmpty
                ? Center(
                    child: Text(
                      'Keine Fächer angelegt.\nTippe auf das + um zu beginnen.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildGlassCard(
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    subject.subjectName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Ø ${subject.average.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                const Divider(height: 1),
                                if (subject.grades.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('Noch keine Noten eingetragen.'),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: subject.grades.length,
                                    itemBuilder: (ctx, i) {
                                      final grade = subject.grades[i];
                                      return ListTile(
                                        title: Text(grade.label),
                                        subtitle: Text('Gewichtung: ${grade.weight}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              grade.value.toStringAsFixed(1),
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20),
                                              color: cs.error,
                                              onPressed: () => _deleteGrade(subject, grade),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _deleteSubject(subject),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Fach löschen'),
                                        style: TextButton.styleFrom(foregroundColor: cs.error),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () => _addGrade(subject),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Note eintragen'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Buffer space for floating bottom navigation bar
          const SizedBox(height: 104),
        ],
      ),
    );
  }
}
