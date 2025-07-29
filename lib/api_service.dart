import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>?> loginOnline(String username, String password) async {
    final url = Uri.parse('https://sistema.inmobiliariatique.com/login.php');
    //final url = Uri.parse('http://50.50.72.97/tique_inmo/login.php');
    final response = await http.post(url, body: {
      'username': username,
      'password': password,
    });

    if (kDebugMode) {
      print(response.body);
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }
    return null;
  }
}
