import 'package:html/parser.dart' as html_parser;

/// Utilidad para parsear y limpiar contenido HTML
///
/// Especialmente útil para el contenido de WordPress que viene en HTML.
class HtmlParser {
  HtmlParser._();

  /// Extrae texto plano de HTML eliminando todas las etiquetas
  ///
  /// ```dart
  /// final clean = HtmlParser.extractPlainText('<p>Hola <strong>mundo</strong></p>');
  /// // clean = "Hola mundo"
  /// ```
  static String extractPlainText(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      return document.body?.text.trim() ?? '';
    } catch (e) {
      // Si falla el parsing, retornar el string original
      return htmlString;
    }
  }

  /// Limpia HTML manteniendo solo etiquetas básicas de formato
  ///
  /// Remueve scripts, estilos y etiquetas peligrosas, pero mantiene
  /// párrafos, negritas, links, etc.
  static String cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);

      // Remover scripts y styles
      document.querySelectorAll('script, style').forEach((element) {
        element.remove();
      });

      return document.body?.innerHtml ?? htmlString;
    } catch (e) {
      return htmlString;
    }
  }

  /// Extrae la primera imagen del contenido HTML
  ///
  /// Útil para mostrar una vista previa cuando no hay featured image
  static String? extractFirstImage(String htmlString) {
    if (htmlString.isEmpty) return null;

    try {
      final document = html_parser.parse(htmlString);
      final img = document.querySelector('img');
      return img?.attributes['src'];
    } catch (e) {
      return null;
    }
  }

  /// Extrae un resumen limitado del texto HTML
  ///
  /// [maxLength] Longitud máxima del resumen
  /// [suffix] Sufijo a agregar si se trunca (default: '...')
  static String extractSummary(
    String htmlString, {
    int maxLength = 150,
    String suffix = '...',
  }) {
    final plainText = extractPlainText(htmlString);

    if (plainText.length <= maxLength) {
      return plainText;
    }

    // Truncar en el último espacio antes del límite
    final truncated = plainText.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');

    if (lastSpace > 0) {
      return '${truncated.substring(0, lastSpace)}$suffix';
    }

    return '$truncated$suffix';
  }

  /// Cuenta palabras en el contenido HTML
  static int countWords(String htmlString) {
    final plainText = extractPlainText(htmlString);
    if (plainText.isEmpty) return 0;

    return plainText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  /// Estima el tiempo de lectura en minutos
  ///
  /// Asume un promedio de 200 palabras por minuto
  static int estimateReadingTime(String htmlString) {
    final words = countWords(htmlString);
    final minutes = (words / 200).ceil();
    return minutes > 0 ? minutes : 1;
  }
}
