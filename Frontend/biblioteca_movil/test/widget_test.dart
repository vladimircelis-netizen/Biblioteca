import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

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
}
