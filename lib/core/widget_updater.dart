import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _appGroupId = '<YOUR_APP_GROUP_ID>'; // For iOS, usually group.com.yourcompany.app

Future<void> updateHomescreenWidget() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final schoolUrl = prefs.getString('schoolUrl') ?? '';
    final personId = prefs.getInt('personId') ?? 0;
    
    final schoolName = prefs.getString('schoolName') ?? '';
    final personType = prefs.getInt('personType') ?? 2;
    
    // Find next lesson
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = DateFormat('yyyyMMdd').format(currentMonday);
    
    final cacheKey = [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      personType.toString(),
      personId.toString(),
      mondayStr,
    ].join('|');
    
    final weekDataStr = prefs.getString(cacheKey);
    if (weekDataStr == null) return;
    
    final decodedPayload = jsonDecode(weekDataStr);
    if (decodedPayload is! Map || !decodedPayload.containsKey('weekData')) return;
    
    final Map<String, dynamic> rawMap = decodedPayload['weekData'];
    
    // We only care about today for the 2x2 widget
    final dayIndex = now.weekday - 1; // 0 for Monday
    if (dayIndex < 0 || dayIndex > 4) {
      await _clearWidget();
      return;
    }
    
    final lessons = rawMap[dayIndex.toString()] as List<dynamic>? ?? [];
    if (lessons.isEmpty) {
      await _clearWidget();
      return;
    }
    
    final nowInt = now.hour * 100 + now.minute;
    
    final lessonCount = prefs.getInt('widget_lesson_count') ?? 3;
    final upcomingLessons = <Map<String, dynamic>>[];
    
    for (final l in lessons) {
      final endTime = int.tryParse(l['endTime']?.toString() ?? '0') ?? 0;
      if (endTime > nowInt) {
        upcomingLessons.add(l as Map<String, dynamic>);
        if (upcomingLessons.length >= lessonCount) break;
      }
    }
    
    if (upcomingLessons.isEmpty) {
      await _clearWidget();
      return;
    }

    final aliasesStr = prefs.getString('subjectAliases');
    Map<String, dynamic> aliases = {};
    if (aliasesStr != null) {
      try {
        aliases = jsonDecode(aliasesStr) as Map<String, dynamic>;
      } catch (_) {}
    }

    Future<void> saveLesson(Map<String, dynamic>? lesson, String suffix) async {
      if (lesson == null) {
        await HomeWidget.saveWidgetData<String>('widget_next_subject$suffix', '');
        await HomeWidget.saveWidgetData<String>('widget_next_time$suffix', '');
        await HomeWidget.saveWidgetData<String>('widget_next_room$suffix', '');
        return;
      }

      final isCancelled = (lesson['code'] ?? '') == 'cancelled';
      if (isCancelled) {
        await HomeWidget.saveWidgetData<String>('widget_next_subject$suffix', 'Fällt aus');
        await HomeWidget.saveWidgetData<String>('widget_next_time$suffix', '');
        await HomeWidget.saveWidgetData<String>('widget_next_room$suffix', '');
        return;
      }

      final subjRaw = lesson['_subjectLong']?.toString().isNotEmpty == true 
          ? lesson['_subjectLong'].toString() 
          : lesson['_subjectShort']?.toString() ?? '?';
      
      var subj = subjRaw;
      if (aliases.containsKey(subjRaw) && aliases[subjRaw].toString().isNotEmpty) {
        subj = aliases[subjRaw].toString();
      }
      
      final start = _formatTime(lesson['startTime']?.toString() ?? '');
      final end = _formatTime(lesson['endTime']?.toString() ?? '');
      final room = lesson['_room']?.toString() ?? '';
      
      await HomeWidget.saveWidgetData<String>('widget_next_subject$suffix', subj);
      await HomeWidget.saveWidgetData<String>('widget_next_time$suffix', '$start - $end');
      await HomeWidget.saveWidgetData<String>('widget_next_room$suffix', room);
    }

    await saveLesson(upcomingLessons.isNotEmpty ? upcomingLessons[0] : null, '');
    await saveLesson(upcomingLessons.length > 1 ? upcomingLessons[1] : null, '2');
    await saveLesson(upcomingLessons.length > 2 ? upcomingLessons[2] : null, '3');
    
    await HomeWidget.updateWidget(name: 'TimetableWidgetProvider');
    
  } catch (e) {
    print('Widget Update Error: $e');
  }
}

Future<void> _clearWidget() async {
  await HomeWidget.saveWidgetData<String>('widget_next_subject', 'Frei');
  await HomeWidget.saveWidgetData<String>('widget_next_time', '--:--');
  await HomeWidget.saveWidgetData<String>('widget_next_room', '');
  await HomeWidget.saveWidgetData<String>('widget_next_subject2', '');
  await HomeWidget.saveWidgetData<String>('widget_next_time2', '');
  await HomeWidget.saveWidgetData<String>('widget_next_room2', '');
  await HomeWidget.saveWidgetData<String>('widget_next_subject3', '');
  await HomeWidget.saveWidgetData<String>('widget_next_time3', '');
  await HomeWidget.saveWidgetData<String>('widget_next_room3', '');
  await HomeWidget.updateWidget(name: 'TimetableWidgetProvider');
}

String _formatTime(String t) {
  if (t.length < 3) return t;
  final padded = t.padLeft(4, '0');
  return '${padded.substring(0, 2)}:${padded.substring(2, 4)}';
}
