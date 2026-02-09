
enum PaylisherNotificationType {
  push('push'),
  inApp('inApp'),
  actionBased('actionBased'),
  geofence('geofence'),
  unknown('unknown');

  final String value;
  const PaylisherNotificationType(this.value);

  static PaylisherNotificationType fromString(String? value) {
    return PaylisherNotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaylisherNotificationType.unknown,
    );
  }
}

class PaylisherNotificationButton {
  final String label;
  final String action;

  PaylisherNotificationButton({
    required this.label,
    required this.action,
  });

  factory PaylisherNotificationButton.fromMap(Map<String, dynamic> map) {
    return PaylisherNotificationButton(
      label: map['label'] as String? ?? '',
      action: map['action'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'action': action,
    };
  }
}

class PaylisherNotification {
  final String? title;
  final String? message;
  final String? imageUrl;
  final String? iconUrl;
  final String? action;
  final bool silent;
  final PaylisherNotificationType type;
  final List<PaylisherNotificationButton>? buttons;
  final Map<String, dynamic>? payload;

  PaylisherNotification({
    this.title,
    this.message,
    this.imageUrl,
    this.iconUrl,
    this.action,
    this.silent = false,
    this.type = PaylisherNotificationType.unknown,
    this.buttons,
    this.payload,
  });

  factory PaylisherNotification.fromMap(Map<String, dynamic> map) {
    return PaylisherNotification(
      title: map['title'] as String?,
      message: map['message'] as String?,
      imageUrl: map['imageUrl'] as String?,
      iconUrl: map['iconUrl'] as String?,
      action: map['action'] as String?,
      silent: map['silent'] as bool? ?? false,
      type: PaylisherNotificationType.fromString(map['type'] as String?),
      buttons: (map['buttons'] as List<dynamic>?)
          ?.map((e) => PaylisherNotificationButton.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      payload: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'action': action,
      'silent': silent,
      'type': type.value,
      'buttons': buttons?.map((e) => e.toMap()).toList(),
      'payload': payload,
    };
  }
}
