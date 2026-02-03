import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:simple_tv_navigation/simple_tv_navigation.dart';
import '../../../core/constants/app_constants.dart';

/// Barra de controles de video para Android TV
///
/// Se muestra DEBAJO del video, no como overlay
/// Incluye: Play/Pause, Volumen, indicador EN VIVO
class TVVideoControlsBar extends ConsumerStatefulWidget {
  final VideoPlayerController? videoController;
  final VoidCallback? onToggleFullscreen;

  const TVVideoControlsBar({
    super.key,
    required this.videoController,
    this.onToggleFullscreen,
  });

  @override
  ConsumerState<TVVideoControlsBar> createState() => _TVVideoControlsBarState();
}

class _TVVideoControlsBarState extends ConsumerState<TVVideoControlsBar> {
  double _volume = 1.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _volume = widget.videoController?.value.volume ?? 1.0;
    _isMuted = _volume == 0;
  }

  void _togglePlayPause() {
    final controller = widget.videoController;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    final controller = widget.videoController;
    if (controller == null) return;

    setState(() {
      if (_isMuted) {
        controller.setVolume(_volume > 0 ? _volume : 1.0);
        _isMuted = false;
      } else {
        _volume = controller.value.volume;
        controller.setVolume(0);
        _isMuted = true;
      }
    });
  }

  void _increaseVolume() {
    final controller = widget.videoController;
    if (controller == null) return;

    setState(() {
      _volume = (_volume + 0.1).clamp(0.0, 1.0);
      controller.setVolume(_volume);
      _isMuted = _volume == 0;
    });
  }

  void _decreaseVolume() {
    final controller = widget.videoController;
    if (controller == null) return;

    setState(() {
      _volume = (_volume - 0.1).clamp(0.0, 1.0);
      controller.setVolume(_volume);
      _isMuted = _volume == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.videoController;
    final isPlaying = controller?.value.isPlaying ?? false;
    final isInitialized = controller?.value.isInitialized ?? false;

    if (!isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Controles centrados
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause
              _buildControlButton(
                id: 'tv_ctrl_playpause',
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pausar' : 'Reproducir',
                onPressed: _togglePlayPause,
                rightId: 'tv_ctrl_voldown',
                leftId: 'nav_0',
              ),

              const SizedBox(width: AppConstants.spacingSm),

              // Volume Down
              _buildControlButton(
                id: 'tv_ctrl_voldown',
                icon: Icons.volume_down,
                onPressed: _decreaseVolume,
                leftId: 'tv_ctrl_playpause',
                rightId: 'tv_ctrl_mute',
              ),

              // Mute
              _buildControlButton(
                id: 'tv_ctrl_mute',
                icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                onPressed: _toggleMute,
                leftId: 'tv_ctrl_voldown',
                rightId: 'tv_ctrl_volup',
              ),

              // Volume Up
              _buildControlButton(
                id: 'tv_ctrl_volup',
                icon: Icons.volume_up,
                onPressed: _increaseVolume,
                leftId: 'tv_ctrl_mute',
                rightId: 'tv_ctrl_fullscreen',
              ),

              const SizedBox(width: AppConstants.spacingSm),

              // Fullscreen
              _buildControlButton(
                id: 'tv_ctrl_fullscreen',
                icon: Icons.fullscreen,
                label: 'Pantalla Completa',
                onPressed: widget.onToggleFullscreen,
                leftId: 'tv_ctrl_volup',
                rightId: 'guide_day_0', // Ir al contenido
              ),
            ],
          ),

          const SizedBox(width: AppConstants.spacingMd),

          // Indicador de volumen
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _isMuted ? 0 : _volume,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String id,
    required IconData icon,
    String? label,
    VoidCallback? onPressed,
    String? leftId,
    String? rightId,
  }) {
    return TVFocusable(
      id: id,
      leftId: leftId,
      rightId: rightId,
      upId: 'guide_program_0', // Conectar arriba al contenido
      downId: 'mini_banner', // Conectar abajo al miniplayer si existe
      onSelect: onPressed,
      showDefaultFocusDecoration: false,
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFocused
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isFocused
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
    );
  }
}
