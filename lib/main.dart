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
import 'features/antigolpeia/data/models/authority_report_model.dart';
import 'features/antigolpeia/services/authority_report_service.dart';
import 'services/revenue_cat_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  await RevenueCatService.initialize(
    dotenv.env['REVENUE_API_KEY'] ?? '',
  );

  await Hive.initFlutter();
  Hive.registerAdapter(FraudPatternModelAdapter());
  Hive.registerAdapter(WhitelistItemAdapter());
  Hive.registerAdapter(BlacklistItemAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(AuthorityReportModelAdapter());
  await AiDatasetService.initialize();
  await GuardService.initialize();
  await BlockEngineService.initialize();
  await AuthorityReportService.initialize();
  await Hive.openBox<AppSettings>('app_settings');
  await BackgroundSyncService().init();

  WhatsAppMonitorService().init();
  await NotificationService().init();

  runApp(const AntiGolpeApp());
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
