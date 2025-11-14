import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paylisher_flutter/paylisher_flutter.dart';
import 'package:paylisher_flutter/src/paylisher_flutter_io.dart';
import 'package:paylisher_flutter/src/paylisher_flutter_platform_interface.dart';
import 'package:paylisher_flutter/src/paylisher_observer.dart';

import 'paylisher_flutter_platform_interface_fake.dart';

void main() {
  PageRoute<dynamic> route(RouteSettings? settings) => PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => Container(),
        settings: settings,
      );

  final fake = PaylisherFlutterPlatformFake();

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PaylisherFlutterPlatformInterface.instance = fake;
  });

  tearDown(() {
    fake.screenName = null;
    PaylisherFlutterPlatformInterface.instance = PaylisherFlutterIO();
  });

  PaylisherObserver getSut(
      {ScreenNameExtractor nameExtractor = defaultNameExtractor,
      PaylisherRouteFilter routeFilter = defaultPaylisherRouteFilter}) {
    return PaylisherObserver(
        nameExtractor: nameExtractor, routeFilter: routeFilter);
  }

  test('returns current route name', () {
    final currentRoute = route(const RouteSettings(name: 'Current Route'));

    final sut = getSut();
    sut.didPush(currentRoute, null);

    expect(fake.screenName, 'Current Route');
  });

  test('returns overriden route name', () {
    final currentRoute = route(const RouteSettings(name: 'Current Route'));

    String? nameExtractor(RouteSettings settings) => 'overriden';

    final sut = getSut(nameExtractor: nameExtractor);
    sut.didPush(currentRoute, null);

    expect(fake.screenName, 'overriden');
  });

  test('returns overriden root route name', () {
    final currentRoute = route(const RouteSettings(name: '/'));

    final sut = getSut();
    sut.didPush(currentRoute, null);

    expect(fake.screenName, 'root (\'/\')');
  });

  test('does not capture not named routes', () {
    final currentRoute = route(const RouteSettings(name: null));

    final sut = getSut();
    sut.didPush(currentRoute, null);

    expect(fake.screenName, null);
  });

  test('does not capture blank routes', () {
    final currentRoute = route(const RouteSettings(name: '  '));

    final sut = getSut();
    sut.didPush(currentRoute, null);

    expect(fake.screenName, null);
  });

  test('does not capture filtered routes', () {
    // CustomOverlawRoute isn't a PageRoute
    final overlayRoute = CustomOverlawRoute(
      settings: const RouteSettings(name: 'Overlay Route'),
    );

    final sut = getSut();
    sut.didPush(overlayRoute, null);

    expect(fake.screenName, null);
  });

  test('allows overriding the route filter', () {
    final overlayRoute = CustomOverlawRoute(
      settings: const RouteSettings(name: 'Overlay Route'),
    );

    bool defaultPaylisherRouteFilter(Route<dynamic>? route) =>
        route is PageRoute || route is OverlayRoute;

    final sut = getSut(routeFilter: defaultPaylisherRouteFilter);
    sut.didPush(overlayRoute, null);

    expect(fake.screenName, 'Overlay Route');
  });
}

class CustomOverlawRoute extends OverlayRoute {
  CustomOverlawRoute({super.settings});

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return [];
  }
}
