import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Diálogo reutilizable para reproducir videos de YouTube de ejercicios maestros.
///
/// Este widget maneja:
/// - Inicialización y disposición del YoutubePlayerController
/// - Extracción del videoId de la URL
/// - Casos donde no hay video disponible
class VideoPlayerDialog extends StatefulWidget {
  final String? videoUrl;
  final String ejercicioNombre;

  const VideoPlayerDialog({
    super.key,
    this.videoUrl,
    required this.ejercicioNombre,
  });

  /// Extrae el videoId de una URL de YouTube
  ///
  /// Soporta:
  /// - https://www.youtube.com/watch?v=dQw4w9WgXcQ
  /// - https://youtu.be/dQw4w9WgXcQ
  /// - dQw4w9WgXcQ (solo el ID)
  static String? extractVideoId(String? url) {
    if (url == null || url.isEmpty) return null;

    // Si ya es solo el ID (11 caracteres alpanuméricos)
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    // Buscar en URLs de YouTube estándar
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
    );

    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late YoutubePlayerController _controller;
  bool _hasVideo = false;

  @override
  void initState() {
    super.initState();

    // Extraer videoId y verificar si hay video disponible
    final videoId = VideoPlayerDialog.extractVideoId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      _hasVideo = true;

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          showLiveFullscreenButton: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_hasVideo) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) {
      return AlertDialog(
        title: const Text('Video no disponible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'El ejercicio "${widget.ejercicioNombre}" no tiene video disponible.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(widget.ejercicioNombre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reproductor de YouTube
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.amber,
            progressColors: const ProgressBarColors(
              playedColor: Colors.amber,
              handleColor: Colors.amberAccent,
            ),
            onReady: () {
              debugPrint('Video player ready for ${widget.ejercicioNombre}');
            },
            onEnded: (_) {
              debugPrint('Video ended for ${widget.ejercicioNombre}');
            },
          ),
          const SizedBox(height: 12),
          // Controles de reproducción personalizados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: _controller.value.isPlaying ? 'Pausa' : 'Reproducir',
                child: IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed:
                      _controller.value.isPlaying
                          ? _controller.pause
                          : _controller.play,
                  iconSize: 32,
                ),
              ),
              Tooltip(
                message: 'Retroceder 10s',
                child: IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final currentSeconds = _controller.value.position.inSeconds;
                    _controller.seekTo(
                      Duration(seconds: (currentSeconds - 10).clamp(0, 9999)),
                    );
                  },
                ),
              ),
              Tooltip(
                message: 'Avanzar 10s',
                child: IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final currentSeconds = _controller.value.position.inSeconds;
                    _controller.seekTo(Duration(seconds: currentSeconds + 10));
                  },
                ),
              ),
              Tooltip(
                message:
                    _controller.value.isFullScreen
                        ? 'Salir de pantalla completa'
                        : 'Pantalla completa',
                child: IconButton(
                  icon: Icon(
                    _controller.value.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                  ),
                  onPressed: _controller.toggleFullScreenMode,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
