import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/video_player_provider.dart';
import '../../schedule/models/program_model.dart'; // Usar modelo unificado
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';

/// Widget que muestra la guía de programación del canal
///
/// Permite navegar por días de la semana y ver los programas programados.
class ProgramGuideWidget extends ConsumerStatefulWidget {
  const ProgramGuideWidget({super.key});

  @override
  ConsumerState<ProgramGuideWidget> createState() => _ProgramGuideWidgetState();
}

class _ProgramGuideWidgetState extends ConsumerState<ProgramGuideWidget> {
  // 1 = Lunes, 7 = Domingo
  int _selectedDay = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsByDayProvider(_selectedDay));
    final isTv = ref.watch(isTvProvider);

    return Column(
      children: [
        // Selector de días
        _buildDaySelector(isTv),
        const Divider(height: 1),

        // Lista de programas
        Expanded(
          child: programsAsync.when(
            data: (programs) {
              if (programs.isEmpty) {
                return _buildEmptyState();
              }
              return _buildProgramsList(programs, isTv);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(bool isTv) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingSm,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final isSelected = dayNumber == _selectedDay;
          final isToday = dayNumber == DateTime.now().weekday;

          // En modo TV, usar TVChip
          if (isTv) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXs,
              ),
              child: TVChip(
                id: 'guide_day_$index',
                leftId: index == 0
                    ? 'tv_ctrl_fullscreen'
                    : 'guide_day_${index - 1}', // Ir a controles
                rightId: index < 6 ? 'guide_day_${index + 1}' : null,
                downId: 'guide_program_0',
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedDay = dayNumber;
                  });
                },
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(days[index]),
                    if (isToday && !isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          color: AppTheme.liveIndicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          // Modo normal - ChoiceChip
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXs,
            ),
            child: ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(days[index]),
                  if (isToday && !isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.liveIndicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDay = dayNumber;
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramsList(List<Program> programs, bool isTv) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return GuideProgramCard(
          program: program,
          onTap: () => _showProgramDetails(context, program, isTv),
          // Solo pasar TV IDs si estamos en modo TV
          tvId: isTv ? 'guide_program_$index' : null,
          tvUpId: isTv
              ? (index == 0 ? 'guide_day_0' : 'guide_program_${index - 1}')
              : null,
          tvDownId: isTv
              ? (index < programs.length - 1
                  ? 'guide_program_${index + 1}'
                  : null)
              : null,
          tvLeftId:
              isTv ? 'tv_ctrl_playpause' : null, // Ir a controles del video
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv_off_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'No hay programación para este día',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Error al cargar la programación',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo con detalles del programa
  void _showProgramDetails(BuildContext context, Program program, bool isTv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: program.isLive
                    ? AppTheme.liveIndicatorColor
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                program.isLive ? 'EN VIVO' : 'PRÓXIMAMENTE',
                style: TextStyle(
                  color: program.isLive ? Colors.white : null,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program Image
              if (program.imageUrl != null && program.imageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: program.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
              Text(
                program.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Text(program.timeRange),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 8),
                  Text('${program.durationInMinutes} minutos'),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(program.dayName),
                ],
              ),
              if (program.description.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingMd),
                const Divider(),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  program.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          // En modo TV, usar TVButton para el botón de cerrar
          if (isTv)
            TVButton(
              id: 'dialog_close',
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
        ],
      ),
    );
  }
}

/// Card individual de programa con soporte TV opcional
class GuideProgramCard extends StatelessWidget {
  const GuideProgramCard({
    required this.program,
    this.onTap,
    this.tvId,
    this.tvUpId,
    this.tvDownId,
    this.tvLeftId,
    this.tvRightId,
    super.key,
  });

  final Program program;
  final VoidCallback? onTap;
  final String? tvId;
  final String? tvUpId;
  final String? tvDownId;
  final String? tvLeftId;
  final String? tvRightId;

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          // Horario
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.startTimeFormatted,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  program.endTimeFormatted,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppConstants.spacingMd),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (program.isLive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.liveIndicatorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        program.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (program.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    program.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Duración
          Column(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(height: 2),
              Text(
                '${program.durationInMinutes}\'',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );

    // Si tiene TV ID, usar TVCard
    if (tvId != null) {
      return TVCard(
        id: tvId!,
        upId: tvUpId,
        downId: tvDownId,
        leftId: tvLeftId,
        rightId: tvRightId,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        onTap: onTap,
        child: cardContent,
      );
    }

    // Fallback a Card normal
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: cardContent,
      ),
    );
  }
}
