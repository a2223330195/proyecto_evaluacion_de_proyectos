import 'package:coachhub/services/image_preload_service.dart';
import 'package:coachhub/widgets/ficha_asesorado/entrenamientos_card.dart';
import 'package:coachhub/widgets/ficha_asesorado/lotes_programados_card.dart';
import 'package:coachhub/widgets/ficha_asesorado/pagos_ficha_widget.dart';
import 'package:coachhub/widgets/ficha_asesorado/bitacora_ficha_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/blocs/pagos/pagos_bloc.dart';
import 'package:coachhub/blocs/bitacora/bitacora_bloc.dart';
import 'package:coachhub/blocs/ficha_asesorado/ficha_asesorado_bloc.dart';
import 'package:coachhub/blocs/ficha_asesorado/ficha_asesorado_event.dart';
import 'package:coachhub/blocs/ficha_asesorado/ficha_asesorado_state.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_bloc.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_event.dart';
import 'package:coachhub/blocs/metricas/metricas_bloc.dart';
import 'package:coachhub/widgets/optimized_cached_image.dart';
import 'package:coachhub/models/asesorado_model.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/string_formatters.dart';
import 'planes_nutricionales_screen.dart';
import 'metricas_detalle_screen.dart';
import 'nuevo_asesorado_screen.dart';
import 'package:coachhub/blocs/planes_nutricionales/planes_nutricionales_bloc.dart';

class FichaAsesoradoScreen extends StatefulWidget {
  final int asesoradoId;

  const FichaAsesoradoScreen({super.key, required this.asesoradoId});

  @override
  State<FichaAsesoradoScreen> createState() => _FichaAsesoradoScreenState();
}

class _FichaAsesoradoScreenState extends State<FichaAsesoradoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final FichaAsesoradoBloc _fichaAsesoradoBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    ImagePreloadService.instance.preloadAsesoradoImages(widget.asesoradoId);
    _fichaAsesoradoBloc =
        FichaAsesoradoBloc()..add(LoadFichaAsesorado(widget.asesoradoId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fichaAsesoradoBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _fichaAsesoradoBloc,
      child: Scaffold(
        body: BlocConsumer<FichaAsesoradoBloc, FichaAsesoradoState>(
          listener: (context, state) {
            if (state is FichaAsesoradoError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is FichaAsesoradoLoaded) {
              final asesorado = state.asesorado;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => NuevoAsesoradoScreen(
                                    asesorado: asesorado,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(0),
                      child:
                          BlocListener<FichaAsesoradoBloc, FichaAsesoradoState>(
                            listener: (context, state) {
                              if (state is FichaAsesoradoLoaded) {
                                BlocProvider.of<FichaAsesoradoBloc>(
                                  context,
                                ).add(LoadFichaAsesorado(widget.asesoradoId));
                              }
                            },
                            child: const SizedBox.shrink(),
                          ),
                    ),
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final mediaQuery = MediaQuery.of(context);
                        final collapsedHeight =
                            kToolbarHeight + mediaQuery.padding.top;
                        final expandedHeight = 220.0;
                        final currentHeight = constraints.biggest.height;

                        // Calcular factor de expansión (0.0 = colapsado, 1.0 = expandido)
                        final expansionFactor = ((currentHeight -
                                    collapsedHeight) /
                                (expandedHeight - collapsedHeight))
                            .clamp(0.0, 1.0);

                        final isCollapsed = expansionFactor < 0.3;
                        final showAvatar =
                            expansionFactor >
                            0.5; // Mostrar avatar solo si > 50% expandido

                        // Avatar grande cuando expandido, pequeño cuando colapsado
                        final radius = showAvatar ? 65.0 : 32.0;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.navyBlue,
                                    AppColors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            Positioned(
                              top: isCollapsed ? -40 : -60,
                              left: -30,
                              child: Container(
                                width: isCollapsed ? 140 : 200,
                                height: isCollapsed ? 140 : 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: isCollapsed ? -30 : -50,
                              right: -20,
                              child: Container(
                                width: isCollapsed ? 110 : 160,
                                height: isCollapsed ? 110 : 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 8,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: isCollapsed ? 12 : 0,
                                ),
                                child:
                                    showAvatar
                                        ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Visibility(
                                              visible: showAvatar,
                                              child: _buildProfileAvatar(
                                                radius,
                                                asesorado.avatarUrl,
                                              ),
                                            ),
                                            Visibility(
                                              visible: showAvatar,
                                              child: const SizedBox(width: 12),
                                            ),
                                            Flexible(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    asesorado.name,
                                                    textAlign: TextAlign.start,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                        : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              asesorado.name,
                                              textAlign: TextAlign.start,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(tabController: _tabController),
                  ),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInformacionTab(asesorado),
                        BlocProvider(
                          create: (context) => BitacoraBloc(),
                          child: BitacoraFichaWidget(asesoradoId: asesorado.id),
                        ),
                        BlocProvider(
                          create:
                              (context) =>
                                  EntrenamientosBloc()
                                    ..add(LoadEntrenamientos(asesorado.id)),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                LotesProgramadosCard(asesoradoId: asesorado.id),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Divider(height: 1),
                                ),
                                EntrenamientosCard(asesoradoId: asesorado.id),
                              ],
                            ),
                          ),
                        ),
                        BlocProvider(
                          create: (context) => MetricasBloc(),
                          child: MetricasDetalleScreen(
                            asesoradoId: asesorado.id,
                            isEmbedded: true,
                            alturaAsesorado: asesorado.alturaCm,
                          ),
                        ),
                        BlocProvider(
                          create: (context) => PagosBloc(),
                          child: PagosFichaWidget(asesoradoId: asesorado.id),
                        ),
                        BlocProvider(
                          create: (context) => PlanesNutricionalesBloc(),
                          child: PlanesNutricionalesView(
                            asesoradoId: asesorado.id,
                            isEmbedded: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text('No se pudieron cargar los datos del asesorado.'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double radius, String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        child: const Icon(Icons.person, color: Colors.white),
      );
    }

    return OptimizedCachedCircleAvatar(
      imagePath: avatarUrl,
      radius: radius,
      backgroundColor: Colors.white24,
      placeholderIcon: Icons.person_outline,
    );
  }

  Widget _buildInformacionTab(Asesorado asesorado) {
    final inicioPrograma = _formatDate(asesorado.fechaInicioPrograma);
    final vencimiento = _formatDate(asesorado.dueDate);
    final altura = _formatAltura(asesorado.alturaCm);
    final telefono =
        asesorado.telefono?.trim().isNotEmpty == true
            ? asesorado.telefono!
            : 'N/A';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Edad',
                  asesorado.edad != null ? '${asesorado.edad} años' : 'N/A',
                ),
                if (asesorado.fechaNacimiento != null)
                  _buildInfoRow(
                    'Fecha de Nacimiento',
                    DateFormat('dd/MM/yyyy').format(asesorado.fechaNacimiento!),
                  ),
                _buildInfoRow(
                  'Sexo',
                  asesorado.sexo?.trim().isNotEmpty == true
                      ? formatUserFacingLabel(asesorado.sexo!)
                      : 'N/A',
                ),
                _buildInfoRow('Altura', altura),
                _buildInfoRow('Teléfono', telefono),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Programa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Inicio', inicioPrograma),
                _buildInfoRow('Vencimiento', vencimiento),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objetivos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildObjectiveItem('Principal', asesorado.objetivoPrincipal),
                const SizedBox(height: 12),
                _buildObjectiveItem('Secundario', asesorado.objetivoSecundario),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(String label, String? value) {
    final hasValue = value?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasValue ? value! : 'Sin definir',
          style: TextStyle(
            color: hasValue ? Colors.black87 : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatAltura(double? altura) {
    if (altura == null) {
      return 'N/A';
    }
    final rounded = altura.roundToDouble();
    if (rounded == altura) {
      return '${rounded.toInt()} cm';
    }
    return '${altura.toStringAsFixed(1)} cm';
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  static const double _tabBarHeight = kTextTabBarHeight;
  static const double _padding = 16.0;

  _TabBarDelegate({required this.tabController});

  @override
  double get minExtent => _tabBarHeight + _padding;

  @override
  double get maxExtent => _tabBarHeight + _padding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        isScrollable: false,
        tabs: const [
          Tab(text: 'Información'),
          Tab(text: 'Bitácora'),
          Tab(text: 'Entrenamientos'),
          Tab(text: 'Métricas'),
          Tab(text: 'Pagos'),
          Tab(text: 'Nutrición'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController;
  }
}
