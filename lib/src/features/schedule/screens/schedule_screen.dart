import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../widgets/program_card.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final scheduleAsync = ref.watch(scheduleProvider(selectedDate));

    // Activate Realtime subscription (just watching it activates the provider)
    ref.watch(scheduleRealtimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programación'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _DateSelector(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).setDate(date);
            },
          ),
        ),
      ),
      body: scheduleAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                // Trigger refresh
                ref.read(scheduleRefreshProvider.notifier).refresh();
                // Wait a bit for the new data to load
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Text('No hay programación disponible para este día'),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Trigger refresh
              ref.read(scheduleRefreshProvider.notifier).refresh();
              // Wait a bit for the new data to load
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                // Usar TVCard para cada programa
                return ProgramCard(
                  program: programs[index],
                  tvId: 'schedule_program_$index',
                  tvUpId: index == 0
                      ? 'schedule_date_0'
                      : 'schedule_program_${index - 1}',
                  tvDownId: index < programs.length - 1
                      ? 'schedule_program_${index + 1}'
                      : 'mini_banner', // Último elemento conecta al MiniPlayer
                  tvLeftId: 'nav_1',
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error al cargar la programación: $error')),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.add(Duration(days: index)));

    return Container(
      height: 60,
      color: Theme.of(context).cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, now);

          // Usar TVChip para navegación TV
          return TVChip(
            id: 'schedule_date_$index',
            leftId: index == 0 ? 'nav_1' : 'schedule_date_${index - 1}',
            rightId:
                index < dates.length - 1 ? 'schedule_date_${index + 1}' : null,
            downId: 'schedule_program_0', // Ir al primer programa
            selected: isSelected,
            onTap: () => onDateSelected(date),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isToday
                      ? 'HOY'
                      : DateFormat('EEE', 'es').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
