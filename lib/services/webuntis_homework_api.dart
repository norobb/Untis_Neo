import 'dart:convert';
import 'package:untisplus/http_proxy.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' as app_state;

class Homework {
  final String id;
  final String subjectCode;
  final String subjectLongName;
  final String teacherName;
  final String description;
  final String remark;
  final String dueDate;
  final bool isDone;
  final int attachmentsCount;

  Homework({
    required this.id,
    required this.subjectCode,
    this.subjectLongName = '',
    this.teacherName = '',
    required this.description,
    this.remark = '',
    required this.dueDate,
    required this.isDone,
    this.attachmentsCount = 0,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: (json['id'] ?? '0').toString(),
      subjectCode: (json['subject'] ?? json['subjectCode'] ?? 'N/A').toString(),
      description: (json['text'] ?? json['description'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? json['dueDateTime'] ?? '').toString(),
      isDone: json['completed'] == true || json['isDone'] == true,
      remark: (json['remark'] ?? '').toString(),
      attachmentsCount: (json['attachments'] as List?)?.length ?? 0,
    );
  }
}

class WebUntisHomeworkApi {
  static const String _clientAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  static Future<bool> setHomeworkDone(String homeworkId, bool done) async {
    if (app_state.demoModeNotifier.value) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final doneList = prefs.getStringList('local_done_homeworks') ?? [];
      if (done) {
        if (!doneList.contains(homeworkId)) {
          doneList.add(homeworkId);
        }
      } else {
        doneList.remove(homeworkId);
      }
      await prefs.setStringList('local_done_homeworks', doneList);
      
      final sessionId = app_state.sessionID;
      if (sessionId.isEmpty) return true; // Local success

      var cleanServerUrl = app_state.schoolUrl.trim();
      cleanServerUrl = cleanServerUrl
          .replaceAll("https://", "")
          .replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }

      final url = Uri.parse(
        "https://$cleanServerUrl/WebUntis/jsonrpc.do?school=${app_state.schoolName}",
      );

      // Attempt API call silently
      http.post(
        url,
        headers: {
          'Cookie': 'JSESSIONID=$sessionId',
          'Content-Type': 'application/json',
          'User-Agent': _clientAgent,
        },
        body: jsonEncode({
          "id": "set_hw_done",
          "method": "setHomeWorkDone",
          "params": {
            "homeworkId": int.tryParse(homeworkId) ?? 0,
            "completed": done
          },
          "jsonrpc": "2.0"
        }),
      );

      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<List<Homework>> fetchHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final doneList = prefs.getStringList('local_done_homeworks') ?? [];
    
    final list = await _fetchHomeworksInternal();
    return list.map((hw) {
      if (doneList.contains(hw.id)) {
        return Homework(
          id: hw.id,
          subjectCode: hw.subjectCode,
          subjectLongName: hw.subjectLongName,
          teacherName: hw.teacherName,
          description: hw.description,
          remark: hw.remark,
          dueDate: hw.dueDate,
          isDone: true,
          attachmentsCount: hw.attachmentsCount,
        );
      }
      return hw;
    }).toList();
  }

  static Future<List<Homework>> _fetchHomeworksInternal() async {
    if (app_state.demoModeNotifier.value) {
      return [
        Homework(
          id: "1",
          subjectCode: "Ma",
          description: "S. 45 Nr. 3-5",
          dueDate: "2026-05-26",
          isDone: false,
        ),
        Homework(
          id: "2",
          subjectCode: "En",
          description: "Read Chapter 4",
          dueDate: "2026-05-27",
          isDone: true,
        ),
      ];
    }

    try {
      final sessionId = app_state.sessionID;
      final schoolName = app_state.schoolName;
      if (sessionId.isEmpty) {
        throw Exception(
          "Keine aktive Session. Bitte aktualisiere den Stundenplan.",
        );
      }

      var cleanServerUrl = app_state.schoolUrl.trim();
      cleanServerUrl = cleanServerUrl
          .replaceAll("https://", "")
          .replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final start = monday.subtract(const Duration(days: 7));
      final end = start.add(const Duration(days: 30));

      final startStrInt =
          "${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}";
      final endStrInt =
          "${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}";

      // 1. Try REST API (/api/homeworks/lessons) - Highly efficient
      try {
        final uri = Uri.parse(
          'https://$cleanServerUrl/WebUntis/api/homeworks/lessons?startDate=$startStrInt&endDate=$endStrInt',
        );
        final res = await http.get(
          uri,
          headers: {
            'Cookie': 'JSESSIONID=$sessionId; schoolname=$schoolName',
            'Accept': 'application/json',
            'User-Agent': _clientAgent,
          },
        );

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final hws = decoded['data']?['homeworks'] as List?;
          final lessonsList = decoded['data']?['lessons'] as List? ?? [];
          final recordsList = decoded['data']?['records'] as List? ?? [];

          final Map<int, String> lessonSubjects = {};
          for (final l in lessonsList) {
            final id = l['id'] as int?;
            final subj = l['subject']?.toString();
            if (id != null && subj != null) lessonSubjects[id] = subj;
          }
          for (final r in recordsList) {
            final id = r['lessonId'] as int? ?? r['id'] as int?;
            final subj = r['subject']?.toString();
            if (id != null && subj != null) lessonSubjects[id] = subj;
          }

          if (hws != null && hws.isNotEmpty) {
            return hws.map((hw) {
              final due = (hw['dueDate'] ?? 0).toString();
              String dueStr = due;
              if (due.length == 8) {
                dueStr = '${due.substring(0, 4)}-${due.substring(4, 6)}-${due.substring(6, 8)}';
              }

              final lessonId = hw['lessonId'] as int?;
              final mappedSubject = lessonId != null ? lessonSubjects[lessonId] : null;

              return Homework(
                id: (hw['id'] ?? 0).toString(),
                subjectCode: (hw['subject'] ?? mappedSubject ?? 'N/A').toString(),
                description: (hw['text'] ?? '').toString(),
                remark: (hw['remark'] ?? '').toString(),
                dueDate: dueStr,
                isDone: hw['completed'] == true,
                attachmentsCount: (hw['attachments'] as List?)?.length ?? 0,
              );
            }).toList();
          }
        }
      } catch (_) {}

      // 2. Try JSON-RPC (getHomeWork2017)
      try {
        final rpcUrl = Uri.parse(
          "https://$cleanServerUrl/WebUntis/jsonrpc.do?school=$schoolName",
        );

        final rpcResponse = await http.post(
          rpcUrl,
          headers: {
            'Cookie': 'JSESSIONID=$sessionId',
            'Content-Type': 'application/json',
            'User-Agent': _clientAgent,
          },
          body: jsonEncode({
            "id": "get_hw",
            "method": "getHomeWork2017",
            "params": [
              app_state.personId,
              "STUDENT",
              startStrInt,
              endStrInt
            ],
            "jsonrpc": "2.0"
          }),
        );

        if (rpcResponse.statusCode == 200) {
          final data = jsonDecode(rpcResponse.body);
          if (data['result'] != null && data['result'] is List) {
            final List<Homework> homeworkList = [];
            for (final hw in data['result']) {
              homeworkList.add(Homework.fromJson(hw));
            }
            if (homeworkList.isNotEmpty) return homeworkList;
          }
        }
      } catch (_) {}

      // 3. REST API Fallback (Original complex logic)
      final startStrRest =
          "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      final endStrRest =
          "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

      final timetableUrl = Uri.parse(
        "https://$cleanServerUrl/WebUntis/api/rest/view/v1/timetable/entries?start=$startStrRest&end=$endStrRest&format=8&resourceType=STUDENT&resources=${app_state.personId}&timetableType=MY_TIMETABLE",
      );

      String encodedSchoolName() {
        try {
          return '_${base64Encode(utf8.encode(schoolName))}';
        } catch (_) {
          return schoolName;
        }
      }

      final schoolCookieCandidates = <String>{
        encodedSchoolName(),
        schoolName,
      }.where((e) => e.isNotEmpty).toList(growable: false);

      Map<String, String> buildHeaders(String schoolCookie) {
        return {
          'Cookie': 'JSESSIONID=$sessionId; schoolname=$schoolCookie',
          'Accept': 'application/json',
          'User-Agent': _clientAgent,
        };
      }

      http.Response? tResp;
      String? workingCookie;

      for (final cookie in schoolCookieCandidates) {
        try {
          final res = await http.get(
            timetableUrl,
            headers: buildHeaders(cookie),
          );
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
              final detailUrl = Uri.parse(
                "https://$cleanServerUrl/WebUntis/api/rest/view/v2/calendar-entry/detail?elementId=${app_state.personId}&elementType=5&endDateTime=$eEnc&startDateTime=$sEnc&homeworkOption=DUE",
              );

              try {
                final dResp = await http.get(
                  detailUrl,
                  headers: buildHeaders(workingCookie),
                );
                if (dResp.statusCode == 200) {
                  final dData = jsonDecode(dResp.body);
                  final cEntries = dData['calendarEntries'] as List? ?? [];
                    if (cEntries.isNotEmpty) {
                      final cEntry = cEntries[0];
                      final subjectCode =
                          cEntry['subject']?['displayName']?.toString() ?? 'N/A';
                      final subjectLongName =
                          cEntry['subject']?['longName']?.toString() ?? '';
                      final teacherName =
                          (cEntry['teachers'] as List?)?.isNotEmpty == true
                              ? cEntry['teachers'][0]['longName']?.toString() ?? ''
                              : '';
                      final homeworks = cEntry['homeworks'] as List? ?? [];

                      for (final hw in homeworks) {
                        final hwId = hw['id'] as int? ?? 0;
                        if (!processedHomeworkIds.contains(hwId)) {
                          processedHomeworkIds.add(hwId);
                          final due = hw['dueDateTime']?.toString() ?? '';
                          final dueParsed = due.contains('T')
                              ? due.split('T').first
                              : due;

                          homeworkList.add(
                            Homework(
                              id: hwId.toString(),
                              subjectCode: subjectCode,
                              subjectLongName: subjectLongName,
                              teacherName: teacherName,
                              description: hw['text']?.toString() ?? '',
                              remark: hw['remark']?.toString() ?? '',
                              dueDate: dueParsed,
                              isDone: hw['completed'] == true,
                              attachmentsCount: (hw['attachments'] as List?)?.length ?? 0,
                            ),
                          );
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
