
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/libro.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _iniciarBaseDatos();
    return _database!;
  }

  
  Future<Database> _iniciarBaseDatos() async {
    final ruta = join(
      await getDatabasesPath(),
      'biblioteca_local.db',
    );

    return await openDatabase(
      ruta,
      version: 3,

      // Se ejecuta cuando la base de datos se crea por primera vez
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE libros (
            id INTEGER PRIMARY KEY,
            titulo TEXT NOT NULL,
            isbn TEXT NOT NULL,
            anioPublicacion INTEGER NOT NULL,
            stock INTEGER NOT NULL,
            autorId INTEGER NOT NULL,
            nombreAutor TEXT NOT NULL,
            rutaPdf TEXT,
            rutaPortada TEXT
          )
        ''');
      },

      // Se ejecuta cuando ya existe una versión anterior
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE libros ADD COLUMN rutaPdf TEXT',
          );
        }

        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE libros ADD COLUMN rutaPortada TEXT',
          );
        }
      },
    );
  }

  
  Future<void> guardarLibros(List<Libro> libros) async {
    final db = await database;

    await db.transaction((txn) async {

      // 1. Obtener los ID de los libros recibidos
      // desde MySQL a través de la API.
      final idsServidor = libros.map((libro) => libro.id).toList();

      // 2. Eliminar de SQLite los libros que ya
      // no existen en MySQL.
      if (idsServidor.isEmpty) {
        await txn.delete('libros');
      } else {
        final marcadores =
            List.filled(idsServidor.length, '?').join(',');

        await txn.delete(
          'libros',
          where: 'id NOT IN ($marcadores)',
          whereArgs: idsServidor,
        );
      }

      // 3. Insertar o actualizar los libros existentes.
      for (final libro in libros) {

        // Consultar las rutas PDF y portadas guardadas.
        final resultado = await txn.query(
          'libros',
          columns: ['rutaPdf', 'rutaPortada'],
          where: 'id = ?',
          whereArgs: [libro.id],
          limit: 1,
        );

        String? rutaPdfGuardada;
        String? rutaPortadaGuardada;

        if (resultado.isNotEmpty) {
          rutaPdfGuardada =
              resultado.first['rutaPdf'] as String?;

          rutaPortadaGuardada =
              resultado.first['rutaPortada'] as String?;
        }

        // Convertir el libro a Map.
        final datos = libro.toMap();

        // Conservar las rutas existentes.
        datos['rutaPdf'] =
            libro.rutaPdf ?? rutaPdfGuardada;

        datos['rutaPortada'] =
            libro.rutaPortada ?? rutaPortadaGuardada;

        // Insertar o actualizar el libro.
        await txn.insert(
          'libros',
          datos,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  
  Future<List<Libro>> obtenerLibros() async {
    final db = await database;

    final resultado = await db.query('libros');

    return resultado.map((fila) {
      return Libro.fromJson(fila);
    }).toList();
  }

  
  Future<void> guardarRutaPdf(
    int libroId,
    String rutaPdf,
  ) async {
    final db = await database;

    await db.update(
      'libros',
      {'rutaPdf': rutaPdf},
      where: 'id = ?',
      whereArgs: [libroId],
    );
  }


  
  Future<void> guardarRutaPortada(
    int libroId,
    String rutaPortada,
  ) async {
    final db = await database;

    await db.update(
      'libros',
      {'rutaPortada': rutaPortada},
      where: 'id = ?',
      whereArgs: [libroId],
    );
  }




}
