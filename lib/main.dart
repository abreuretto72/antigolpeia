import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/share_extension_handler.dart';
import 'features/antigolpe/services/whatsapp_monitor_service.dart';
import 'services/notification_service.dart';
import 'features/antigolpeia/data/models/fraud_pattern_model.dart';
import 'features/antigolpeia/data/models/whitelist_item.dart';
import 'features/antigolpeia/data/models/blacklist_item.dart';
import 'features/antigolpeia/data/models/app_settings.dart';
import 'features/antigolpeia/services/ai_dataset_service.dart';
import 'features/antigolpeia/services/background_sync_service.dart';
import 'features/antigolpeia/services/guard_service.dart';
import 'features/antigolpeia/services/block_engine_service.dart';
import 'features/antigolpeia/data/models/analysis_stats_model.dart';
import 'services/activity_counter.dart';
import 'features/antigolpeia/data/models/authority_report_model.dart';
import 'features/antigolpeia/services/authority_report_service.dart';
import 'services/foreground_task_service.dart';
import 'services/revenue_cat_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Handler global para erros do framework Flutter
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
  };

  // runZonedGuarded captura todos os erros Dart async não tratados
  runZonedGuarded(_bootstrap, (error, stack) {
    debugPrint('[ZoneError] $error\n$stack');
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── .env ──────────────────────────────────────────────────────────────────
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[main] .env não carregado: $e');
  }

  // ── Supabase ──────────────────────────────────────────────────────────────
  try {
    await Supabase.initialize(
      url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint('[main] Supabase.initialize falhou: $e');
  }

  // ── RevenueCat ────────────────────────────────────────────────────────────
  // Só inicializa com chave de produção — chave test_ bloqueia o app em
  // builds de distribuição. Beta usa sem assinatura.
  final rcKey = dotenv.env['REVENUE_API_KEY'] ?? '';
  if (rcKey.isNotEmpty && !rcKey.startsWith('test_')) {
    try {
      await RevenueCatService.initialize(rcKey);
    } catch (e) {
      debugPrint('[main] RevenueCat.initialize falhou: $e');
    }
  } else {
    debugPrint('[main] RevenueCat ignorado (chave ausente ou test_)');
  }

  // ── Hive: init + adapters + boxes ─────────────────────────────────────────
  try {
    await Hive.initFlutter();
    // registerAdapter ignora silenciosamente se o adapter já estiver registrado
    _registerHiveAdapter(FraudPatternModelAdapter());
    _registerHiveAdapter(WhitelistItemAdapter());
    _registerHiveAdapter(BlacklistItemAdapter());
    _registerHiveAdapter(AppSettingsAdapter());
    _registerHiveAdapter(AuthorityReportModelAdapter());
    _registerHiveAdapter(AnalysisStatsAdapter());
    await Hive.openBox<AppSettings>('app_settings');
    await Hive.openBox<AnalysisStats>(AnalysisStats.boxName);
    ActivityCounter().init();
  } catch (e) {
    debugPrint('[main] Hive init falhou: $e');
  }

  // ── Serviços de dados ─────────────────────────────────────────────────────
  try {
    await AiDatasetService.initialize();
    await GuardService.initialize();
    await BlockEngineService.initialize();
    await AuthorityReportService.initialize();
  } catch (e) {
    debugPrint('[main] Serviços de dados init falhou: $e');
  }

  // ── Sync em background ────────────────────────────────────────────────────
  try {
    await BackgroundSyncService().init();
  } catch (e) {
    debugPrint('[main] BackgroundSync init falhou: $e');
  }

  // ── Monitores ─────────────────────────────────────────────────────────────
  try {
    WhatsAppMonitorService().init();
    await NotificationService().init();
  } catch (e) {
    debugPrint('[main] Monitores init falhou: $e');
  }

  // ── Foreground task ───────────────────────────────────────────────────────
  try {
    ForegroundTaskService.initialize();
  } catch (e) {
    debugPrint('[main] ForegroundTask init falhou: $e');
  }

  runApp(const AntiGolpeApp());
}

/// Registra adapter Hive ignorando conflito de typeId já registrado.
void _registerHiveAdapter<T>(TypeAdapter<T> adapter) {
  try {
    Hive.registerAdapter(adapter);
  } catch (e) {
    debugPrint('[Hive] Adapter ${adapter.runtimeType} já registrado: $e');
  }
}

class AntiGolpeApp extends StatelessWidget {
  const AntiGolpeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntiGolpe AI',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShareExtensionHandler().initTextSharing(context);
    });
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    // Vincula usuário já autenticado ao RevenueCat
    if (session != null) {
      await RevenueCatService.instance.linkUser(session.user.id);
      return;
    }

    try {
      final response =
          await Supabase.instance.client.auth.signInAnonymously();
      final userId = response.user?.id;
      if (userId != null) {
        await RevenueCatService.instance.linkUser(userId);
      }
    } catch (e) {
      debugPrint('Erro no login anônimo: $e');
      if (mounted) setState(() => _authFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authFailed) return const LoginPage();

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session
            ?? Supabase.instance.client.auth.currentSession;

        if (session != null) return const HomePage();

        // Ainda aguardando autenticação
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
