import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class CalendarExporter {
  static Future<void> exportWeek(
      Map<int, List<dynamic>> weekData, DateTime currentMonday) async {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//UntisPlus//UntisNeo//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    final DateFormat timeFormat = DateFormat("yyyyMMdd'T'HHmmss");
    final DateFormat tsFormat = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final nowStr = tsFormat.format(DateTime.now().toUtc());

    for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
      final lessons = weekData[dayIndex] ?? [];
      if (lessons.isEmpty) continue;

      final lessonDate = currentMonday.add(Duration(days: dayIndex));

      for (final l in lessons) {
        if ((l['code'] ?? '') == 'cancelled') continue;

        final startTimeStr = (l['startTime']?.toString() ?? '0800').padLeft(4, '0');
        final endTimeStr = (l['endTime']?.toString() ?? '0900').padLeft(4, '0');
        
        int startHour = 8;
        int startMinute = 0;
        int endHour = 9;
        int endMinute = 0;
        
        try {
          startHour = int.parse(startTimeStr.substring(0, 2));
          startMinute = int.parse(startTimeStr.substring(2, 4));
          endHour = int.parse(endTimeStr.substring(0, 2));
          endMinute = int.parse(endTimeStr.substring(2, 4));
        } catch (_) {}

        final startDateTime = DateTime(
          lessonDate.year, lessonDate.month, lessonDate.day, startHour, startMinute);
        final endDateTime = DateTime(
          lessonDate.year, lessonDate.month, lessonDate.day, endHour, endMinute);

        final subject = l['_subjectLong']?.toString() ?? l['_subjectShort']?.toString() ?? 'Unterricht';
        final room = l['_room']?.toString() ?? '';
        final teacher = l['_teacher']?.toString() ?? '';
        
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:${startDateTime.millisecondsSinceEpoch}-${lessonDate.weekday}@untisplus.com');
        buffer.writeln('DTSTAMP:$nowStr');
        
        // Use local time without 'Z' so calendar apps respect the user's timezone
        buffer.writeln('DTSTART:${timeFormat.format(startDateTime)}');
        buffer.writeln('DTEND:${timeFormat.format(endDateTime)}');
        
        buffer.writeln('SUMMARY:$subject');
        if (room.isNotEmpty) {
          buffer.writeln('LOCATION:$room');
        }
        if (teacher.isNotEmpty) {
          buffer.writeln('DESCRIPTION:Lehrkraft: $teacher');
        }
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');

    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy_MM_dd').format(currentMonday);
    final file = File('${dir.path}/stundenplan_$dateStr.ics');
    await file.writeAsString(buffer.toString());

    await OpenFilex.open(file.path);
  }
}
