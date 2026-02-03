/// In-App Message model for mobile app
class InAppMessage {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String buttonText;
  final String? actionUrl;
  final String layout;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;

  InAppMessage({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.buttonText = 'Aceptar',
    this.actionUrl,
    this.layout = 'card',
    this.isActive = true,
    required this.startDate,
    this.endDate,
  });

  factory InAppMessage.fromJson(Map<String, dynamic> json) {
    return InAppMessage(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      buttonText: json['button_text'] as String? ?? 'Aceptar',
      actionUrl: json['action_url'] as String?,
      layout: json['layout'] as String? ?? 'card',
      isActive: json['is_active'] as bool? ?? true,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
    );
  }
}
