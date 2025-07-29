import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'db_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'login_page.dart';

class HomePage extends StatefulWidget {
  final int empleadoId;

  const HomePage({super.key, required this.empleadoId});

  @override
  _ChecadorPageState createState() => _ChecadorPageState();
}

class _ChecadorPageState extends State<HomePage> {
  late final int empleadoId;

  @override
  void initState() {
    super.initState();
    empleadoId = widget.empleadoId;
  }

  Future<void> checar(int tipo) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('GPS desactivado'),
            content: Text('Debes activar la ubicación para continuar. ¿Deseas abrir los ajustes del sistema?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.pop(context);
                },
                child: Text('Abrir ajustes'),
              ),
            ],
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }
    }

    late Position pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (context.mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final fecha = DateFormat('yyyy-MM-dd').format(now);
    final hora = DateFormat('HH:mm:ss').format(now);

    final registro = {
      'inm_empleado_id': empleadoId,
      'inm_tipo_checada_id': tipo,
      'latitud': pos.latitude,
      'longitud': pos.longitude,
      'fecha': fecha,
      'hora': hora,
      'enviado': 0,
    };

    if (!kIsWeb && Platform.isAndroid) {
      int id = await DBHelper.insertar(registro);
      await enviarPendientes();

      if (id > 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Registro insertado correctamente')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al insertar registro')),
          );
        }
      }
    }else{
      try {
        final res = await http.post(
          Uri.parse('https://sistema.inmobiliariatique.com/checador.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(registro),
        );

        if (kDebugMode) print(res.body);

        if (res.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registro insertado correctamente')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al insertar registro: ${res.statusCode}')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de red o servidor: $e')),
          );
        }
      }
    }
  }

  Future<void> enviarPendientes() async {
    final conexion = await Connectivity().checkConnectivity();
    if (conexion == ConnectivityResult.none) return;

    final registros = await DBHelper.obtenerNoEnviados();
    for (var r in registros) {
      final res = await http.post(
        Uri.parse('https://sistema.inmobiliariatique.com/checador.php'),
        //Uri.parse('http://50.50.72.97/tique_inmo/checador.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'inm_empleado_id': r['inm_empleado_id'],
          'inm_tipo_checada_id': r['inm_tipo_checada_id'],
          'latitud': r['latitud'],
          'longitud': r['longitud'],
          'fecha': r['fecha'],
          'hora': r['hora'],
        }),
      );

      if (kDebugMode) {
        print(res.body);
      }

      if (res.statusCode == 500) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al insertar registro')),
          );
        }
      }

      if (res.statusCode == 200) {
        await DBHelper.marcarComoEnviado(r['id']);
      }
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Checador de Asistencia")),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(248, 248, 248, 255),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: .2),
              width: .5)
            ),
            padding:  const EdgeInsets.all(25),
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: 200.0,
                      child: ElevatedButton(
                        child: Text("Checar Entrada"),
                        onPressed: () => checar(1),
                      ),
                    )
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child:SizedBox(
                    width: 200.0,
                    child: ElevatedButton(
                      child: Text("Checar Salida"),
                      onPressed: () => checar(2),
                    ),
                  ),
                )
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child:
            ElevatedButton(
              child: Text("Cerrar Sesion"),
              onPressed: () => _goToLogin(),
            ),
          ),
        ],
      ),
    ),
  );
}
