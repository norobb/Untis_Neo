import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../main.dart' as app_state;

class Absence {
  final int id;
  final String startDate;
  final String endDate;
  final int startTime;
  final int endTime;
  final String reason;
  final String text;
  final bool isExcused;
  final String status;
  final String studentName;

  Absence({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.text,
    required this.isExcused,
    required this.status,
    required this.studentName,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      startTime: int.tryParse(json['startTime']?.toString() ?? '') ?? 0,
      endTime: int.tryParse(json['endTime']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isExcused: json['isExcused'] == true ||
          json['excuse']?['isExcused'] == true ||
          json['excuseStatus'] == 'EXCUSED' ||
          json['excuse']?['excuseStatus'] == 'EXCUSED',
      status: json['excuseStatus']?.toString() ?? json['excuse']?['excuseStatus']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
    );
  }
}

class WebUntisAbsencesApi {
  static const String _clientAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  static Future<List<Absence>> fetchAbsences({DateTime? startRange, DateTime? endRange}) async {
    if (app_state.demoModeNotifier.value) {
      return [
        Absence(
          id: 1,
          startDate: DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 2))),
          endDate: DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 2))),
          startTime: 800,
          endTime: 1300,
          reason: 'Krankheit',
          text: 'Grippe',
          isExcused: true,
          status: 'excused',
          studentName: 'Demo Student',
        ),
        Absence(
          id: 2,
          startDate: DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 10))),
          endDate: DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 10))),
          startTime: 1000,
          endTime: 1100,
          reason: 'Verschlafen',
          text: '',
          isExcused: false,
          status: 'unexcused',
          studentName: 'Demo Student',
        ),
      ];
    }

    try {
      final sessionId = app_state.sessionID;
      final schoolName = app_state.schoolName;
      final schoolUrl = app_state.schoolUrl;
      final personId = app_state.personId;

      if (sessionId.isEmpty || personId == 0) return [];

      var cleanServerUrl = schoolUrl.trim();
      cleanServerUrl = cleanServerUrl
          .replaceAll("https://", "")
          .replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }

      final now = DateTime.now();
      final start = startRange ?? now.subtract(const Duration(days: 365));
      final end = endRange ?? now.add(const Duration(days: 30));
      final startStr = DateFormat('yyyyMMdd').format(start);
      final endStr = DateFormat('yyyyMMdd').format(end);

      final endpoints = [
        '/WebUntis/api/classreg/absences/student?studentId=$personId&startDate=$startStr&endDate=$endStr',
        '/WebUntis/api/classreg/absences/students?startDate=$startStr&endDate=$endStr&studentId=$personId',
        '/WebUntis/api/public/absences?startDate=$startStr&endDate=$endStr',
        '/WebUntis/api/public/classreg/absences?startDate=$startStr&endDate=$endStr&studentId=$personId'
      ];

      for (final endpoint in endpoints) {
        try {
          final uri = Uri.parse('https://$cleanServerUrl$endpoint');
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
            List<dynamic> list = [];
            if (decoded is List) {
              list = decoded;
            } else if (decoded is Map) {
              list = (decoded['data']?['absences'] ?? decoded['absences'] ?? decoded['data'] ?? decoded['result'] ?? []) as List;
              if (list.isEmpty && decoded['data'] is Map && decoded['data'].containsKey('absences')) {
                list = decoded['data']['absences'] as List? ?? [];
              }
            }
            if (list.isNotEmpty) {
              return list.map((e) => Absence.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }
}
