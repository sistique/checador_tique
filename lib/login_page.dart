import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'api_service.dart';
import 'db_helper.dart';
import 'user_model.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  String _message = '';

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> attemptLogin() async {
    final username = _userController.text;
    final password = _passController.text;
    final passwordHash = hashPassword(password);

    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity != ConnectivityResult.none) {
      final data = await ApiService.loginOnline(username, password);
      if (data != null) {
        final empleadoId = int.parse(data['inm_empleado_id']);
        if (!kIsWeb && Platform.isAndroid) {
          await DBHelper.insertUser(User(
            username: username,
            passwordHash: passwordHash,
            empleadoId: empleadoId,
          ));
        }
        _goToHome(empleadoId);
      } else {
        setState(() => _message = 'Credenciales incorrectas (servidor)');
      }
    } else {
      if (!kIsWeb && Platform.isAndroid) {

        final localUser = await DBHelper.getUser(username);
        if (localUser != null && localUser.passwordHash == passwordHash) {
          _goToHome(localUser.empleadoId);
        } else {
          setState(() => _message = 'Credenciales incorrectas (local)');
        }
      }
    }
  }

  void _goToHome(int empleadoId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(empleadoId: empleadoId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Usuario')),
                  TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: attemptLogin, child: const Text('Iniciar sesión')),
                  const SizedBox(height: 10),
                  Text(_message, style: const TextStyle(color: Colors.red)),
                ],
              ),
            )
          ],
        )
      )
    );
  }
}
