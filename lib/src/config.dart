import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.fixtures,
  }) : assert(!fixtures || environment == AppEnvironment.dev);
  factory AppConfig.fromEnvironment() {
    const raw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.byName(raw);
    const fixtures = bool.fromEnvironment('ENABLE_DEV_FIXTURES');
    if (fixtures && environment != AppEnvironment.dev)
      throw StateError('Fixtures are dev-only.');
    return AppConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:3000',
      ),
      fixtures: fixtures,
    );
  }
  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool fixtures;
}

final appConfigProvider = Provider<AppConfig>(
  (_) => throw StateError('AppConfig not initialized'),
);
