// lib/screens/agenda_screen.dart

import 'package:coachhub/models/asignacion_model.dart'; // Importa tu nuevo modelo
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart'; // Dialogo unificado de programación
import 'package:coachhub/screens/detalle_asignacion_screen.dart'; // Nueva pantalla de detalles
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  // Mapa para guardar los eventos cargados
  Map<DateTime, List<Asignacion>> _eventos = {};

  // Día seleccionado por el usuario (inicia en hoy)
  DateTime _selectedDay = DateTime.now();

  // Día que el calendario está mostrando (ej. qué mes)
  DateTime _focusedDay = DateTime.now();

  // Lista de eventos para el día seleccionado
  List<Asignacion> _selectedEvents = [];

  // 🎯 TAREA 3.1: Formato de calendario (mes o semana)
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // ✅ MEJORA 2: Token para evitar race conditions en navegación de meses
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadEventosDelMes(_focusedDay); // Cargar eventos para el mes actual
  }

  // --- LÓGICA DE DATOS ---

  Future<void> _loadEventosDelMes(DateTime month) async {
    // ✅ MEJORA 2: Generar nuevo token para esta carga
    final currentToken = ++_loadToken;

    // Calcula el primer y último día del mes
    final primerDia = DateTime(month.year, month.month, 1);
    final ultimoDia = DateTime(month.year, month.month + 1, 0);

    final db = DatabaseConnection.instance;
    // 🎯 TAREA 3.2: JOINs mejorados con LEFT JOIN y COALESCE para garantizar nombres
    const sql = '''
      SELECT
        ag.id, ag.asesorado_id, ag.plantilla_id, ag.batch_id,
        ag.fecha_asignada, ag.hora_asignada, ag.status, ag.notes,
        COALESCE(a.nombre, 'Asesorado sin nombre') AS asesorado_nombre,
        COALESCE(a.avatar_url, '') AS asesorado_avatar_url,
        COALESCE(r.nombre, 'Rutina sin nombre') AS rutina_nombre
      FROM asignaciones_agenda ag
      LEFT JOIN asesorados a ON ag.asesorado_id = a.id
      LEFT JOIN rutinas_plantillas r ON ag.plantilla_id = r.id
      WHERE ag.fecha_asignada BETWEEN ? AND ?
      ORDER BY ag.hora_asignada ASC
    ''';

    final results = await db.query(sql, [
      DateFormat('yyyy-MM-dd').format(primerDia),
      DateFormat('yyyy-MM-dd').format(ultimoDia),
    ]);

    // ✅ MEJORA 2: Solo actualizar si este token sigue siendo válido
    // (no ha habido otra carga más reciente)
    if (currentToken != _loadToken) {
      return; // Ignorar resultado de una carga antigua
    }

    final Map<DateTime, List<Asignacion>> eventosCargados = {};
    for (final row in results) {
      final asignacion = Asignacion.fromMap(row.fields);
      // Normaliza la fecha para ignorar la hora
      final fecha = DateTime.utc(
        asignacion.fechaAsignada.year,
        asignacion.fechaAsignada.month,
        asignacion.fechaAsignada.day,
      );

      if (eventosCargados[fecha] == null) {
        eventosCargados[fecha] = [];
      }
      eventosCargados[fecha]!.add(asignacion);
    }

    if (mounted) {
      setState(() {
        _eventos = eventosCargados;
        _selectedEvents = _getEventosParaDia(
          _selectedDay,
        ); // Actualiza la lista
      });
    }
  }

  // Función helper para table_calendar
  List<Asignacion> _getEventosParaDia(DateTime day) {
    final fechaNormalizada = DateTime.utc(day.year, day.month, day.day);
    return _eventos[fechaNormalizada] ?? [];
  }

  // --- LÓGICA DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.kDefaultPadding),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            // El Calendario
            Container(
              decoration: AppStyles.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🎯 TAREA 3.1: SegmentedButton para cambiar vista
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vista:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SegmentedButton<CalendarFormat>(
                        segments: const [
                          ButtonSegment<CalendarFormat>(
                            value: CalendarFormat.week,
                            label: Text('Semana'),
                          ),
                          ButtonSegment<CalendarFormat>(
                            value: CalendarFormat.month,
                            label: Text('Mes'),
                          ),
                        ],
                        selected: <CalendarFormat>{_calendarFormat},
                        onSelectionChanged: (Set<CalendarFormat> newSelection) {
                          setState(() {
                            _calendarFormat = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TableCalendar<Asignacion>(
                    locale:
                        'es_ES', // (Asegúrate de configurar la localización)
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                    // --- Conexión de Datos ---
                    eventLoader: _getEventosParaDia,
                    // --- Interacción ---
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedEvents = _getEventosParaDia(selectedDay);
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadEventosDelMes(
                        focusedDay,
                      ); // Carga los eventos del nuevo mes
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // La Lista de Eventos
            Expanded(
              child: Container(
                decoration: AppStyles.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividades para ${DateFormat.yMMMMd('es_ES').format(_selectedDay)}',
                      style: AppStyles.title,
                    ),
                    const Divider(),
                    Expanded(child: _buildEventList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 16),
        const Text(
          'Agenda General',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        ElevatedButton.icon(
          // Este botón podría llevar a 'Asignar Rutina'
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Programar Actividad'),
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder:
                  (context) => ScheduleRoutineDialog(
                    initialStartDate: _selectedDay,
                    initialEndDate: _selectedDay,
                  ),
            );
            if (result == true) {
              _loadEventosDelMes(
                _focusedDay, // _focusedDay ya es un DateTime, no se usa directamente en la query como parámetro de fecha, sino para calcular el rango.
              ); // Refresh events after assignment
            }
          },
        ),
      ],
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return const Center(child: Text('No hay actividades para este día.'));
    }
    return ListView.separated(
      itemCount: _selectedEvents.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final asignacion = _selectedEvents[index];
        final bool isCompleted = asignacion.status == 'completada';

        final horaLabel = asignacion.horaAsignada?.format(context);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        DetalleAsignacionScreen(asignacionId: asignacion.id),
              ),
            );
          },
          child: ListTile(
            leading: _buildAsesoradoAvatar(asignacion.asesoradoAvatarUrl),
            title: Text(asignacion.rutinaNombre ?? 'Rutina sin nombre'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(asignacion.asesoradoNombre ?? 'Asesorado sin nombre'),
                if (horaLabel != null)
                  Text(
                    'Hora: $horaLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (asignacion.notes != null && asignacion.notes!.isNotEmpty)
                  Text(
                    'Nota: ${asignacion.notes}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Marcar como completada',
                    onPressed: () => _marcarComoCompletada(asignacion.id),
                  ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar asignación',
                  onPressed: () => _eliminarAsignacion(asignacion.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LÓGICA DE ACCIONES (CRUD) ---

  void _marcarComoCompletada(int asignacionId) async {
    try {
      final db = DatabaseConnection.instance;
      await db.query('UPDATE asignaciones_agenda SET status = ? WHERE id = ?', [
        'completada',
        asignacionId,
      ]);

      // Recarga los eventos para el mes actual
      _loadEventosDelMes(_focusedDay);

      // ✅ Mostrar feedback de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Asignación marcada como completada'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // ✅ Mostrar feedback de error con opción de reintentar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('❌ Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _marcarComoCompletada(asignacionId),
            ),
          ),
        );
      }
    }
  }

  void _eliminarAsignacion(int asignacionId) async {
    try {
      final db = DatabaseConnection.instance;
      await db.query('DELETE FROM asignaciones_agenda WHERE id = ?', [
        asignacionId,
      ]);

      // Recarga los eventos para el mes actual
      _loadEventosDelMes(_focusedDay);

      // ✅ Mostrar feedback de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Asignación eliminada'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // ✅ Mostrar feedback de error con opción de reintentar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('❌ Error al eliminar: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _eliminarAsignacion(asignacionId),
            ),
          ),
        );
      }
    }
  }

  /// Widget helper para mostrar avatar del asesorado con fallback
  Widget _buildAsesoradoAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return FutureBuilder<File?>(
        future: ImageService.getProfilePicture(avatarUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              backgroundImage: FileImage(snapshot.data!),
              radius: 20,
            );
          }
          return CircleAvatar(radius: 20, child: const Icon(Icons.person));
        },
      );
    }
    return CircleAvatar(radius: 20, child: const Icon(Icons.person));
  }
}
