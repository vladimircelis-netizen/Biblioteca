
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
      version: 5,

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
            rutaPortada TEXT,
            rutaAudio TEXT
          )
        ''');

        await _crearTablaDescargas(db);
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

        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE libros ADD COLUMN rutaAudio TEXT',
          );
        }

        if (oldVersion < 5) {
          await _crearTablaDescargas(db);
        }
      },
    );
  }


  // Archivos (PDF y audio) descargados para usar sin conexión.
  // Es una tabla aparte porque guardarLibros() reemplaza
  // los libros completos en cada sincronización.
  Future<void> _crearTablaDescargas(Database db) async {
    await db.execute('''
      CREATE TABLE descargas (
        libroId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        rutaLocal TEXT NOT NULL,
        urlOrigen TEXT NOT NULL,
        PRIMARY KEY (libroId, tipo)
      )
    ''');
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

      // 3. Insertar o actualizar los libros.
      // La API es la fuente de verdad: las rutas de Cloudinary
      // (portada, PDF y audio) se guardan tal como llegan.
      // Si un archivo se eliminó en el servidor, aquí queda en null.
      for (final libro in libros) {
        await txn.insert(
          'libros',
          libro.toMap(),
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



  Future<void> guardarRutaAudio(
    int libroId,
    String rutaAudio,
  ) async {
    final db = await database;

    await db.update(
      'libros',
      {'rutaAudio': rutaAudio},
      where: 'id = ?',
      whereArgs: [libroId],
    );
  }


  // DESCARGAS

  Future<void> guardarDescarga({
    required int libroId,
    required String tipo,
    required String rutaLocal,
    required String urlOrigen,
  }) async {
    final db = await database;

    await db.insert(
      'descargas',
      {
        'libroId': libroId,
        'tipo': tipo,
        'rutaLocal': rutaLocal,
        'urlOrigen': urlOrigen,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // Devuelve {rutaLocal, urlOrigen} o null si no se ha descargado
  Future<Map<String, Object?>?> obtenerDescarga(
    int libroId,
    String tipo,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'descargas',
      where: 'libroId = ? AND tipo = ?',
      whereArgs: [libroId, tipo],
      limit: 1,
    );

    if (resultado.isEmpty) return null;

    return resultado.first;
  }


  Future<void> eliminarDescarga(
    int libroId,
    String tipo,
  ) async {
    final db = await database;

    await db.delete(
      'descargas',
      where: 'libroId = ? AND tipo = ?',
      whereArgs: [libroId, tipo],
    );
  }

}
