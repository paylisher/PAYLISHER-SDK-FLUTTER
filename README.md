# Paylisher Flutter SDK

Flutter uygulamalarınız için Paylisher analytics entegrasyonu.

[![pub package](https://img.shields.io/pub/v/paylisher_flutter.svg)](https://pub.dev/packages/paylisher_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Kurulum

`pubspec.yaml` dosyanıza ekleyin:
```yaml
dependencies:
  paylisher_flutter: ^1.0.0
```

Sonra çalıştırın:
```bash
flutter pub get
```

## Hızlı Başlangıç

### 1. SDK'yı Başlatın
```dart
import 'package:paylisher_flutter/paylisher_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = PaylisherConfig(
    apiKey: 'YOUR_API_KEY',
    host: 'https://ds.paylisher.com',
    debug: true, // Geliştirme için true yapın
  );
  
  await Paylisher().setup(config);
  
  runApp(MyApp());
}
```

### 2. Event Yakalayın
```dart
// Basit event
Paylisher().capture(eventName: 'button_clicked');

// Property'li event
Paylisher().capture(
  eventName: 'purchase_completed',
  properties: {
    'product_id': '12345',
    'price': 99.99,
    'currency': 'TRY',
  },
);
```

### 3. Kullanıcı Tanımlayın
```dart
Paylisher().identify(
  userId: 'user_123',
  userProperties: {
    'name': 'Yusuf',
    'email': 'yusuf@example.com',
    'plan': 'premium',
  },
);
```

### 4. Ekran Görüntüleme
```dart
Paylisher().screen(
  screenName: 'Home Screen',
  properties: {
    'source': 'deep_link',
  },
);
```

## Yapılandırma Seçenekleri
```dart
final config = PaylisherConfig(
  apiKey: 'YOUR_API_KEY',
  host: 'https://ds.paylisher.com',
  
  // Debug modu
  debug: false,
  
  // Event gönderme ayarları
  flushAt: 20,              // Kaç event birikince gönderilsin
  flushInterval: 30,        // Kaç saniyede bir gönderilsin
  maxQueueSize: 1000,       // Maksimum kuyruk boyutu
  maxBatchSize: 50,         // Tek seferde maksimum event
  
  // Feature flags
  preloadFeatureFlags: true,
  sendFeatureFlagEvents: true,
  
  // Session replay (deneysel)
  sessionReplay: false,
  
  // Yaşam döngüsü eventleri
  captureApplicationLifecycleEvents: true,
  
  // Kişi profilleri
  personProfiles: PersonProfiles.identifiedOnly,
);
```

## API Referansı

### Event Yakalama
```dart
// Basit event
Paylisher().capture(eventName: 'event_name');

// Property'li event
Paylisher().capture(
  eventName: 'event_name',
  properties: {'key': 'value'},
);
```

### Kullanıcı Tanımlama
```dart
Paylisher().identify(
  userId: 'unique_user_id',
  userProperties: {'name': 'John'},
  userPropertiesSetOnce: {'created_at': DateTime.now().toIso8601String()},
);
```

### Ekran Görüntüleme
```dart
Paylisher().screen(
  screenName: 'Screen Name',
  properties: {'key': 'value'},
);
```

### Grup
```dart
Paylisher().group(
  groupType: 'company',
  groupKey: 'company_123',
  groupProperties: {'name': 'Acme Inc'},
);
```

### Alias
```dart
Paylisher().alias(alias: 'new_distinct_id');
```

### Feature Flags
```dart
// Feature flag kontrolü
bool isEnabled = await Paylisher().isFeatureEnabled(key: 'new_feature');

// Feature flag değeri
var value = await Paylisher().getFeatureFlag(key: 'feature_key');

// Feature flag payload
var payload = await Paylisher().getFeatureFlagPayload(key: 'feature_key');

// Feature flags'ları yenile
await Paylisher().reloadFeatureFlags();
```

### Super Properties
```dart
// Her event'e eklenecek property kaydet
Paylisher().register(key: 'app_version', value: '1.0.0');

// Property'yi kaldır
Paylisher().unregister(key: 'app_version');
```

### Opt In/Out
```dart
// Veri toplamayı durdur
Paylisher().disable();

// Veri toplamayı başlat
Paylisher().enable();

// Durumu kontrol et
bool isOptOut = await Paylisher().isOptOut();
```

### Diğer Metodlar
```dart
// Distinct ID al
String distinctId = await Paylisher().getDistinctId();

// Event'leri hemen gönder
await Paylisher().flush();

// SDK'yı sıfırla (yeni kullanıcı için)
await Paylisher().reset();

// Debug modunu aç/kapa
Paylisher().debug(enable: true);

// SDK'yı kapat
await Paylisher().close();
```

## Platform Yapılandırması

### Android

`android/app/build.gradle` dosyasında minimum SDK versiyonunu ayarlayın:
```gradle
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

### iOS

`ios/Podfile` dosyasında minimum iOS versiyonunu ayarlayın:
```ruby
platform :ios, '13.0'
```

## Örnek Uygulama

Tam bir örnek için [example](./example) klasörüne bakın.
```dart
import 'package:flutter/material.dart';
import 'package:paylisher_flutter/paylisher_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Paylisher().setup(PaylisherConfig(
    apiKey: 'YOUR_API_KEY',
    host: 'https://ds.paylisher.com',
    debug: true,
  ));
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ekran görüntüleme
    Paylisher().screen(screenName: 'Home');
    
    return Scaffold(
      appBar: AppBar(title: Text('Paylisher Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Event yakalama
            Paylisher().capture(
              eventName: 'button_clicked',
              properties: {'button': 'demo'},
            );
          },
          child: Text('Track Event'),
        ),
      ),
    );
  }
}
```

## Sorun Giderme

### Event'ler gönderilmiyor

1. `debug: true` yaparak logları kontrol edin
2. API key'in doğru olduğundan emin olun
3. Host URL'inin doğru olduğundan emin olun
4. İnternet bağlantısını kontrol edin

### Feature flags yüklenmiyor

1. `preloadFeatureFlags: true` olduğundan emin olun
2. Paylisher dashboard'da feature flag'lerin tanımlı olduğundan emin olun

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen bir pull request göndermeden önce issue açın.

## Lisans

MIT License - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Destek

- 📧 Email: support@paylisher.com
- 📚 Docs: https://docs.paylisher.com
- 🐛 Issues: https://github.com/paylisher/paylisher-flutter/issues