import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart' as app_state;

class Homework {
  final String id;
  final String subjectCode;
  final String description;
  final String dueDate;
  final bool isDone;

  Homework({
    required this.id,
    required this.subjectCode,
    required this.description,
    required this.dueDate,
    required this.isDone,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    // Handled in API logic directly
    return Homework(
      id: "0",
      subjectCode: "",
      description: "",
      dueDate: "",
      isDone: false,
    );
  }
}

class WebUntisHomeworkApi {
  static const String _clientAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  static Future<List<Homework>> fetchHomeworks() async {
    if (app_state.demoModeNotifier.value) {
      return [
        Homework(id: "1", subjectCode: "Ma", description: "S. 45 Nr. 3-5", dueDate: "2026-05-26", isDone: false),
        Homework(id: "2", subjectCode: "En", description: "Read Chapter 4", dueDate: "2026-05-27", isDone: true),
      ];
    }

    try {
      final sessionId = app_state.sessionID;
      if (sessionId.isEmpty) {
        throw Exception("Keine aktive Session. Bitte aktualisiere den Stundenplan.");
      }

      var cleanServerUrl = app_state.schoolUrl.trim();
      cleanServerUrl = cleanServerUrl.replaceAll("https://", "").replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }

      String encodedSchoolName() {
        try {
          return '_${base64Encode(utf8.encode(app_state.schoolName))}';
        } catch (_) {
          return app_state.schoolName;
        }
      }

      final schoolCookieCandidates = <String>{
        encodedSchoolName(),
        app_state.schoolName,
      }.where((e) => e.isNotEmpty).toList(growable: false);

      Map<String, String> buildHeaders(String schoolCookie) {
        return {
          'Cookie': 'JSESSIONID=$sessionId; schoolname=$schoolCookie',
          'Accept': 'application/json',
          'User-Agent': _clientAgent,
        };
      }

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final start = monday.subtract(const Duration(days: 7));
      final end = start.add(const Duration(days: 30));

      final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

      final timetableUrl = Uri.parse("https://$cleanServerUrl/WebUntis/api/rest/view/v1/timetable/entries?start=$startStr&end=$endStr&format=8&resourceType=STUDENT&resources=${app_state.personId}&timetableType=MY_TIMETABLE");

      http.Response? tResp;
      String? workingCookie;

      for (final cookie in schoolCookieCandidates) {
        try {
          final res = await http.get(timetableUrl, headers: buildHeaders(cookie));
          if (res.statusCode == 200) {
            tResp = res;
            workingCookie = cookie;
            break;
          }
        } catch (_) {}
      }

      if (tResp == null || workingCookie == null) {
        throw Exception("Stundenplan-Abruf für Hausaufgaben fehlgeschlagen.");
      }

      final tData = jsonDecode(tResp.body);
      final days = tData['data']?['days'] as List? ?? [];
      final List<Homework> homeworkList = [];
      final Set<int> processedHomeworkIds = {};

      for (final day in days) {
        final gridEntries = day['gridEntries'] as List? ?? [];
        for (final entry in gridEntries) {
          final icons = entry['icons'] as List? ?? [];
          if (icons.contains('HOMEWORK')) {
            final duration = entry['duration'] as Map? ?? {};
            final startDateTime = duration['start'] ?? '';
            final endDateTime = duration['end'] ?? '';

            if (startDateTime.isNotEmpty && endDateTime.isNotEmpty) {
              final sEnc = Uri.encodeComponent("$startDateTime:00");
              final eEnc = Uri.encodeComponent("$endDateTime:00");
              final detailUrl = Uri.parse("https://$cleanServerUrl/WebUntis/api/rest/view/v2/calendar-entry/detail?elementId=${app_state.personId}&elementType=5&endDateTime=$eEnc&startDateTime=$sEnc&homeworkOption=DUE");

              try {
                final dResp = await http.get(detailUrl, headers: buildHeaders(workingCookie));
                if (dResp.statusCode == 200) {
                  final dData = jsonDecode(dResp.body);
                  final cEntries = dData['calendarEntries'] as List? ?? [];
                  if (cEntries.isNotEmpty) {
                    final cEntry = cEntries[0];
                    final subjectCode = cEntry['subject']?['displayName']?.toString() ?? 'N/A';
                    final homeworks = cEntry['homeworks'] as List? ?? [];
                    
                    for (final hw in homeworks) {
                      final hwId = hw['id'] as int? ?? 0;
                      if (!processedHomeworkIds.contains(hwId)) {
                        processedHomeworkIds.add(hwId);
                        final due = hw['dueDateTime']?.toString() ?? '';
                        final dueParsed = due.contains('T') ? due.split('T').first : due;
                        
                        homeworkList.add(Homework(
                          id: hwId.toString(),
                          subjectCode: subjectCode,
                          description: hw['text']?.toString() ?? '',
                          dueDate: dueParsed,
                          isDone: hw['completed'] == true,
                        ));
                      }
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }
      }

      return homeworkList;

    } catch (e) {
      throw Exception("Fehler beim Laden der Hausaufgaben: $e");
    }
  }
}
