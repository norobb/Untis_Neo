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
    
    Map<String, dynamic>? nextLesson;
    
    for (final l in lessons) {
      final endTime = int.tryParse(l['endTime']?.toString() ?? '0') ?? 0;
      if (endTime > nowInt) {
        nextLesson = l as Map<String, dynamic>;
        break; // First lesson that ends after now
      }
    }
    
    if (nextLesson == null) {
      await _clearWidget();
      return;
    }
    
    final isCancelled = (nextLesson['code'] ?? '') == 'cancelled';
    if (isCancelled) {
      // Logic for cancelled could be different, but for now we just show it.
      await HomeWidget.saveWidgetData<String>('widget_next_subject', 'Fällt aus');
      await HomeWidget.saveWidgetData<String>('widget_next_time', '');
      await HomeWidget.saveWidgetData<String>('widget_next_room', '');
    } else {
      final subjRaw = nextLesson['_subjectLong']?.toString().isNotEmpty == true 
          ? nextLesson['_subjectLong'].toString() 
          : nextLesson['_subjectShort']?.toString() ?? '?';
      
      // Wait, we can't easily access _getSubjectAlias here since it relies on ValueNotifier.
      // We will just read from SharedPreferences directly.
      final aliasesStr = prefs.getString('subjectAliases');
      var subj = subjRaw;
      if (aliasesStr != null) {
        try {
          final aliases = jsonDecode(aliasesStr) as Map<String, dynamic>;
          if (aliases.containsKey(subjRaw) && aliases[subjRaw].toString().isNotEmpty) {
            subj = aliases[subjRaw].toString();
          }
        } catch (_) {}
      }
      
      final start = _formatTime(nextLesson['startTime']?.toString() ?? '');
      final end = _formatTime(nextLesson['endTime']?.toString() ?? '');
      final room = nextLesson['_room']?.toString() ?? '';
      
      await HomeWidget.saveWidgetData<String>('widget_next_subject', subj);
      await HomeWidget.saveWidgetData<String>('widget_next_time', '$start - $end');
      await HomeWidget.saveWidgetData<String>('widget_next_room', room);
    }
    
    await HomeWidget.updateWidget(name: 'TimetableWidgetProvider');
    
  } catch (e) {
    print('Widget Update Error: $e');
  }
}

Future<void> _clearWidget() async {
  await HomeWidget.saveWidgetData<String>('widget_next_subject', 'Frei');
  await HomeWidget.saveWidgetData<String>('widget_next_time', '--:--');
  await HomeWidget.saveWidgetData<String>('widget_next_room', '');
  await HomeWidget.updateWidget(name: 'TimetableWidgetProvider');
}

String _formatTime(String t) {
  if (t.length < 3) return t;
  final padded = t.padLeft(4, '0');
  return '${padded.substring(0, 2)}:${padded.substring(2, 4)}';
}
