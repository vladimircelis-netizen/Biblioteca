
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// Botón "Continuar con Google" usado en el login y en el registro
class BotonGoogleWidget extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;

  const BotonGoogleWidget({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.tarjeta,
          foregroundColor: AppColors.textoPrincipal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Letra "G" con el color de Google
            const Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 12),
            Text(texto),
          ],
        ),
      ),
    );
  }
}


// Separador "o" entre el formulario y el botón de Google
class SeparadorOWidget extends StatelessWidget {
  const SeparadorOWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(color: AppColors.textoSecundario),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
