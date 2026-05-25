import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/webuntis_homework_api.dart';
import '../main.dart'; // To access shared UI components like _glassContainer if they are public, but they are private inside main.dart part 'shared_ui.dart'
// Wait, _glassContainer is private in main.dart?
// I need to check if they are exposed. For now, I will use standard Flutter blur or see how main_navigation_screen uses it.
import 'dart:ui';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Homework> _homeworks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomework();
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
            color: cs.surface.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.transparent, // For custom background
      appBar: AppBar(
        title: Text(
          'Hausaufgaben',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHomework,
          ),
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _homeworks.length,
                      itemBuilder: (context, index) {
                        final hw = _homeworks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildGlassCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: hw.isDone,
                                  onChanged: (v) {
                                    // Local state update only for now
                                    setState(() {
                                      _homeworks[index] = Homework(
                                        id: hw.id,
                                        subjectCode: hw.subjectCode,
                                        description: hw.description,
                                        dueDate: hw.dueDate,
                                        isDone: v ?? false,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hw.subjectCode,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hw.description,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: cs.onSurface,
                                          decoration: hw.isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (hw.dueDate.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Fällig: ${hw.dueDate}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
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
    );
  }
}
