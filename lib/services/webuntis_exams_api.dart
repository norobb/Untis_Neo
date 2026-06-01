import 'dart:convert';
import 'package:untisplus/http_proxy.dart' as http;
import 'package:intl/intl.dart';
import '../main.dart' as app_state;

class WebUntisExamsApi {
  static const String _clientAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  static Future<List<Map<String, dynamic>>> fetchExams() async {
    if (app_state.demoModeNotifier.value) {
      return [
        {
          'id': 1,
          'examType': 'Schulaufgabe',
          'subject': 'Mathematik',
          'examDate': DateFormat('yyyyMMdd').format(DateTime.now().add(const Duration(days: 5))),
          'startTime': 800,
          'endTime': 930,
          'name': 'Analysis & Stochastik',
          'teachers': ['Müller'],
          'rooms': ['R101'],
        }
      ];
    }

    try {
      final sessionId = app_state.sessionID;
      final schoolName = app_state.schoolName;
      final schoolUrl = app_state.schoolUrl;
      
      if (sessionId.isEmpty) return [];

      var cleanServerUrl = schoolUrl.trim();
      cleanServerUrl = cleanServerUrl
          .replaceAll("https://", "")
          .replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 14));
      final end = now.add(const Duration(days: 90));
      final startStr = DateFormat('yyyyMMdd').format(start);
      final endStr = DateFormat('yyyyMMdd').format(end);

      final uri = Uri.parse(
        'https://$cleanServerUrl/WebUntis/api/exams?startDate=$startStr&endDate=$endStr',
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
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = (decoded['data']?['exams'] ?? decoded['exams'] ?? decoded['result'] ?? []) as List;
        }
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }
}
