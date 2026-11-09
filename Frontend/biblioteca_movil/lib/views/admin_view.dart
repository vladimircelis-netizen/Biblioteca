
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'registrar_libro_view.dart';
import 'gestionar_libros_view.dart';

class AdminView extends StatelessWidget {
  final String token;
  const AdminView({super.key,required this.token,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Administración'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Gestión de Biblioteca',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Registrar libro'),
              subtitle: const Text('Agregar un nuevo libro'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrarLibroView(
                      token: token,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Gestionar libros'),
              subtitle: const Text('Editar o eliminar libros'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GestionarLibrosView(
                      token: token,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Archivos digitales'),
              subtitle: const Text('Subir PDF, MP3 y portadas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
