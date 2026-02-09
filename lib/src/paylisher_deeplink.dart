
class PaylisherDeeplink {
  final String url;
  final String? scheme;
  final String? destination;
  final Map<String, dynamic>? parameters;
  final String? campaignId;

  PaylisherDeeplink({
    required this.url,
    this.scheme,
    this.destination,
    this.parameters,
    this.campaignId,
  });

  factory PaylisherDeeplink.fromMap(Map<String, dynamic> map) {
    return PaylisherDeeplink(
      url: map['url'] as String,
      scheme: map['scheme'] as String?,
      destination: map['destination'] as String?,
      parameters: map['parameters'] as Map<String, dynamic>?,
      campaignId: map['campaignId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'scheme': scheme,
      'destination': destination,
      'parameters': parameters,
      'campaignId': campaignId,
    };
  }
}
