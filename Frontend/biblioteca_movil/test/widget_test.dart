import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:biblioteca_movil/config/catalogo_inicial.dart';
import 'package:biblioteca_movil/main.dart';
import 'package:biblioteca_movil/models/usuario.dart';
import 'package:biblioteca_movil/services/sesion_service.dart';
import 'package:biblioteca_movil/views/login_view.dart';

// Crear un JWT de prueba con la fecha de vencimiento indicada
String crearToken(DateTime vencimiento) {
  String parte(Map<String, dynamic> datos) =>
      base64Url.encode(utf8.encode(jsonEncode(datos))).replaceAll('=', '');

  final encabezado = parte({'alg': 'HS256', 'typ': 'JWT'});
  final contenido = parte({
    'exp': vencimiento.millisecondsSinceEpoch ~/ 1000,
  });

  return '$encabezado.$contenido.firma';
}

final usuario = Usuario(
  id: 1,
  nombre: 'Ana',
  apellido: 'Pérez',
  email: 'ana@correo.com',
  rol: 'Lector',
);

void main() {
  testWidgets('El login muestra el correo guardado y el enlace al registro',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        pantallaInicial: LoginView(emailInicial: 'ana@correo.com'),
      ),
    );

    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  test('Un token que vence en el futuro está vigente', () {
    final sesion = Sesion(
      usuario: usuario,
      token: crearToken(DateTime.now().add(const Duration(hours: 1))),
    );

    expect(sesion.tokenVencido, isFalse);
  });

  test('Un token que ya venció se detecta como vencido', () {
    final sesion = Sesion(
      usuario: usuario,
      token: crearToken(
        DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );

    expect(sesion.tokenVencido, isTrue);
  });

  test('Un token inválido se considera vencido', () {
    final sesion = Sesion(usuario: usuario, token: 'no-es-un-jwt');

    expect(sesion.tokenVencido, isTrue);
  });

  test('Una sesión sin token es una cuenta creada sin conexión', () {
    final local = Sesion(usuario: usuario, token: '');
    final servidor = Sesion(
      usuario: usuario,
      token: crearToken(DateTime.now().add(const Duration(hours: 1))),
    );

    expect(local.esCuentaLocal, isTrue);
    expect(servidor.esCuentaLocal, isFalse);
  });

  group('Catálogo incluido en la app', () {
    test('Tiene los tres libros con PDF', () {
      expect(CatalogoInicial.libros, hasLength(3));
      expect(CatalogoInicial.libros.every((l) => l.tienePdf), isTrue);
    });

    test('Busca los libros por ISBN', () {
      expect(
        CatalogoInicial.buscarPorIsbn('9788420412146')?.titulo,
        'Libertad de elegir',
      );
      expect(CatalogoInicial.buscarPorIsbn('0000000000'), isNull);
    });

    test('Todos sus archivos existen en la carpeta assets', () {
      for (final libro in CatalogoInicial.libros) {
        final rutas = [
          libro.rutaPortada,
          libro.rutaPdf,
          libro.rutaAudio,
        ].whereType<String>();

        for (final ruta in rutas) {
          expect(
            File(ruta).existsSync(),
            isTrue,
            reason: 'Falta el archivo $ruta (${libro.titulo})',
          );
        }
      }
    });
  });
}
