import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart' as app_state;

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
    final dueDateInt = json['dueDate'] as int? ?? 0;
    String dueDateStr = "";
    if (dueDateInt > 0) {
      final dYear = dueDateInt ~/ 10000;
      final dMonth = (dueDateInt ~/ 100) % 100;
      final dDay = dueDateInt % 100;
      dueDateStr = "$dYear-${dMonth.toString().padLeft(2, '0')}-${dDay.toString().padLeft(2, '0')}";
    }

    return Homework(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      subjectCode: "N/A", // We can enhance this by matching with lessonIds later
      description: json['text']?.toString() ?? "",
      dueDate: dueDateStr,
      isDone: json['completed'] == true,
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
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('username') ?? '';
      final pass = prefs.getString('password') ?? '';

      if (user.isEmpty || pass.isEmpty) {
        throw Exception("Keine Zugangsdaten gefunden.");
      }

      var cleanServerUrl = app_state.schoolUrl.trim();
      cleanServerUrl = cleanServerUrl.replaceAll("https://", "").replaceAll("http://", "");
      if (cleanServerUrl.contains("/")) {
        cleanServerUrl = cleanServerUrl.split("/")[0];
      }
      
      final schoolEnc = Uri.encodeComponent(app_state.schoolName);
      final baseUrl = "https://$cleanServerUrl/WebUntis/jsonrpc.do?school=$schoolEnc";

      // 1. Authenticate
      final authReq = {
        "id": "auth",
        "method": "authenticate",
        "params": {
          "user": user,
          "password": pass,
          "client": "WebUntis"
        },
        "jsonrpc": "2.0"
      };

      final client = http.Client();
      final authResponse = await client.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": _clientAgent,
        },
        body: jsonEncode(authReq),
      );

      if (authResponse.statusCode != 200) {
        throw Exception("HTTP-Fehler beim Login.");
      }

      final authBody = jsonDecode(authResponse.body);
      if (authBody['error'] != null) {
        throw Exception("WebUntis Fehler: ${authBody['error']['message']}");
      }

      // Calculate Dates (from -7 days to +30 days)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final start = monday.subtract(const Duration(days: 7));
      final end = start.add(const Duration(days: 30));

      final startDate = start.year * 10000 + start.month * 100 + start.day;
      final endDate = end.year * 10000 + end.month * 100 + end.day;

      // 2. Fetch Homework
      final hwReq = {
        "id": "hw",
        "method": "getHomeWork2017",
        "params": {
          "id": app_state.personId,
          "type": "STUDENT",
          "startDate": startDate,
          "endDate": endDate
        },
        "jsonrpc": "2.0"
      };

      final hwResponse = await client.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": _clientAgent,
        },
        body: jsonEncode(hwReq),
      );

      final hwBody = jsonDecode(hwResponse.body);
      if (hwBody['error'] != null) {
        throw Exception("WebUntis Fehler: ${hwBody['error']['message']}");
      }

      final records = hwBody['result']?['records'] as List? ?? hwBody['result'] as List? ?? [];
      final List<Homework> homeworkList = records.map((r) => Homework.fromJson(r as Map<String, dynamic>)).toList();

      // Logout
      await client.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": _clientAgent,
        },
        body: jsonEncode({
          "id": "logout",
          "method": "logout",
          "params": {},
          "jsonrpc": "2.0"
        }),
      );

      client.close();
      return homeworkList;

    } catch (e) {
      throw Exception("Fehler beim Laden der Hausaufgaben: $e");
    }
  }
}
