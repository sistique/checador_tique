import 'package:checador_tique/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {

  static Future<Database> initDBUser() async {
    final path = join(await getDatabasesPath(), 'users.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          username TEXT PRIMARY KEY,
          passwordHash TEXT,
          empleadoId INTEGER
        )
      ''');
    });
  }

  static Future<void> insertUser(User user) async {
    final database = await initDBUser();
    await database.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<User?> getUser(String username) async {
    final database = await initDBUser();
    final result = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) return User.fromMap(result.first);
    return null;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'asistencia.db');
    return openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute('''
        CREATE TABLE registros (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inm_empleado_id INTEGER,
          inm_tipo_checada_id INTEGER,
          latitud REAL,
          longitud REAL,
          fecha TEXT,
          hora TEXT,
          enviado INTEGER
        )
      ''');
    });
  }

  static Future<int> insertar(Map<String, dynamic> registro) async {
    final db = await initDB();
    int id = await db.insert('registros', registro);

    return id;
  }

  static Future<List<Map<String, dynamic>>> obtenerNoEnviados() async {
    final db = await initDB();
    return await db.query('registros', where: 'enviado = 0');
  }

  static Future<void> marcarComoEnviado(int id) async {
    final db = await initDB();
    await db.update('registros', {'enviado': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
