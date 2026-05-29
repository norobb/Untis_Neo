import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untisplus/services/webuntis_homework_api.dart';
import 'package:confetti/confetti.dart';
// To access shared UI components like _glassContainer if they are public, but they are private inside main.dart part 'shared_ui.dart'
// Wait, _glassContainer is private in main.dart?
// I need to check if they are exposed. For now, I will use standard Flutter blur or see how main_navigation_screen uses it.
import 'dart:ui';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Homework> _homeworks = [];
  bool _isLoading = true;
  String? _error;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadHomework();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadHomework() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hw = await WebUntisHomeworkApi.fetchHomeworks();
      setState(() {
        _homeworks = hw;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRemainingDaysChip(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final diff = due
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      final cs = Theme.of(context).colorScheme;

      Color bgColor;
      Color textColor;
      String text;

      if (diff < 0) {
        bgColor = cs.errorContainer.withValues(alpha: 0.5);
        textColor = cs.onErrorContainer;
        text = 'Überfällig';
      } else if (diff == 0) {
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        text = 'Heute';
      } else if (diff == 1) {
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Morgen';
      } else {
        bgColor = cs.secondaryContainer.withValues(alpha: 0.3);
        textColor = cs.onSecondaryContainer;
        text = 'In $diff Tagen';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildProgressSummary() {
    if (_homeworks.isEmpty) return const SizedBox.shrink();

    final int total = _homeworks.length;
    final int done = _homeworks.where((h) => h.isDone).length;
    final double progress = total == 0 ? 0 : done / total;

    final cs = Theme.of(context).colorScheme;

    String message;
    if (progress == 0) {
      message = "Auf geht's! Packen wir es an.";
    } else if (progress < 0.5) {
      message = "Guter Start! Bleib dran.";
    } else if (progress < 1) {
      message = "Fast geschafft! Endspurt.";
    } else {
      message = "Klasse! Alles erledigt. Zeit zum Entspannen.";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _buildGlassCard(
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                    color: progress == 1 ? Colors.green : cs.primary,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$done von $total erledigt',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent, // For custom background
      appBar: AppBar(
        title: Text(
          'Hausaufgaben',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHomework),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHomework,
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            )
          : _homeworks.isEmpty
          ? Center(
              child: Text(
                'Keine Hausaufgaben gefunden.',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHomework,
              color: cs.primary,
              child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
              itemCount: _homeworks.length + 1,
              itemBuilder: (ctx, index) {
                if (index == 0) return _buildProgressSummary();
                
                final hwIndex = index - 1;
                final hw = _homeworks[hwIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildGlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: hw.isDone,
                          onChanged: (v) async {
                            final bool isNowDone = v ?? false;
                            final bool success =
                                await WebUntisHomeworkApi.setHomeworkDone(
                                  hw.id,
                                  isNowDone,
                                );
                            if (success) {
                              if (isNowDone) {
                                _confettiController.play();
                              }
                              setState(() {
                                _homeworks[hwIndex] = Homework(
                                  id: hw.id,
                                  subjectCode: hw.subjectCode,
                                  subjectLongName: hw.subjectLongName,
                                  teacherName: hw.teacherName,
                                  description: hw.description,
                                  remark: hw.remark,
                                  dueDate: hw.dueDate,
                                  isDone: isNowDone,
                                  attachmentsCount: hw.attachmentsCount,
                                );
                              });
                            } else {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fehler beim Aktualisieren der Hausaufgabe',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      hw.subjectLongName.isNotEmpty
                                          ? hw.subjectLongName
                                          : hw.subjectCode,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                  if (hw.dueDate.isNotEmpty)
                                    _buildRemainingDaysChip(hw.dueDate),
                                ],
                              ),
                              if (hw.teacherName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    hw.teacherName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                hw.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: cs.onSurface,
                                  decoration: hw.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (hw.remark.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: cs.secondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          hw.remark,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: cs.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Bis: ${_formatDate(hw.dueDate)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (hw.attachmentsCount > 0) ...[
                                    const Spacer(),
                                    Icon(
                                      Icons.attach_file,
                                      size: 14,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${hw.attachmentsCount}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // point downwards
            maxBlastForce: 10,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }
}
