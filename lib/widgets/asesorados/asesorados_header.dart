import 'dart:developer' as developer;

import 'package:coachhub/screens/nuevo_asesorado_screen.dart';
import 'package:coachhub/screens/planes_editor_screen.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AsesoradosHeader extends StatelessWidget {
  final VoidCallback? onAddAsesorado;
  final VoidCallback? onPlanesUpdated;
  final int? coachId;

  const AsesoradosHeader({
    super.key,
    this.onAddAsesorado,
    this.onPlanesUpdated,
    this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Text(
            'Asesorados',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlanesEditorScreen(),
                ),
              );
              if (onPlanesUpdated != null) {
                onPlanesUpdated!();
              }
            },
            icon: const Icon(Icons.library_books_outlined),
            label: const Text('Planes personalizados'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NuevoAsesoradoScreen(coachId: coachId),
                ),
              );
              developer.log(
                '[AsesoradosHeader] Resultado al volver de NuevoAsesoradoScreen: $result',
                name: 'AsesoradosHeader',
              );
              if (result == true && onAddAsesorado != null) {
                developer.log(
                  '[AsesoradosHeader] Llamando onAddAsesorado callback',
                  name: 'AsesoradosHeader',
                );
                onAddAsesorado!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('+ Nuevo Asesorado'),
          ),
        ],
      ),
    );
  }
}
