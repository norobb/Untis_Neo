import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../web/file_download_helper.dart' if (dart.library.io) '../web/file_download_helper_stub.dart';

class CalendarExporter {
  static Future<void> exportWeek(
    Map<int, List<dynamic>> weekData, 
    DateTime currentMonday
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//UntisPlus//DE');
    
    final dateFormat = DateFormat("yyyyMMdd'T'HHmmss");
    final now = dateFormat.format(DateTime.now());

    for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
      final date = currentMonday.add(Duration(days: dayIndex));
      final dateString = DateFormat('yyyyMMdd').format(date);
      
      final dayLessons = weekData[dayIndex] ?? [];
      for (final lesson in dayLessons) {
        if (lesson is! Map) continue;
        
        final isCancelled = lesson['cellState'] == 'CANCEL';
        
        // Parse time properly - Untis times are ints like 800 for 08:00
        int startTime = int.tryParse(lesson['startTime']?.toString() ?? '0') ?? 0;
        int endTime = int.tryParse(lesson['endTime']?.toString() ?? '0') ?? 0;
        
        final startHour = (startTime ~/ 100).toString().padLeft(2, '0');
        final startMin = (startTime % 100).toString().padLeft(2, '0');
        final endHour = (endTime ~/ 100).toString().padLeft(2, '0');
        final endMin = (endTime % 100).toString().padLeft(2, '0');
        
        final startStr = "${dateString}T$startHour$startMin\00";
        final endStr = "${dateString}T$endHour$endMin\00";
        
        final subject = (lesson['subjects'] as List?)?.map((s) => s['name']).join(', ') ?? '';
        final room = (lesson['rooms'] as List?)?.map((r) => r['name']).join(', ') ?? '';
        final teacher = (lesson['teachers'] as List?)?.map((t) => t['name']).join(', ') ?? '';
        final info = lesson['lstext'] ?? '';
        
        String summary = subject;
        if (isCancelled) summary = "[ENTFÄLLT] $summary";
        
        String location = room;
        
        String description = "Lehrer: $teacher\\nRaum: $room";
        if (info.toString().isNotEmpty) {
          description += "\\nInfo: $info";
        }

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:${lesson['id']}@untisplus');
        buffer.writeln('DTSTAMP:$now');
        buffer.writeln('DTSTART:$startStr');
        buffer.writeln('DTEND:$endStr');
        buffer.writeln('SUMMARY:$summary');
        buffer.writeln('LOCATION:$location');
        buffer.writeln('DESCRIPTION:$description');
        if (isCancelled) {
          buffer.writeln('STATUS:CANCELLED');
        }
        buffer.writeln('END:VEVENT');
      }
    }
    
    buffer.writeln('END:VCALENDAR');
    final filename = 'stundenplan_${DateFormat('yyyyMMdd').format(currentMonday)}.ics';

    if (kIsWeb) {
      await downloadTextFile(filename: filename, content: buffer.toString());
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buffer.toString());
      await OpenFilex.open(file.path);
    }
  }
}
