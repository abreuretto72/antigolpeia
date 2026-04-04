import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../data/models/fraud_pattern_model.dart';
import 'ai_dataset_service.dart';

/// Nomes de tarefas — zero hardcoded inline.
class _Tasks {
  static const String syncPatterns = 'com.antigolpeia.sync_patterns';
}

/// Ponto de entrada do WorkManager — executa em isolate separado.
/// Deve reinicializar todas as dependências (Hive, Supabase, dotenv).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');

      await Supabase.initialize(
        url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
      );

      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FraudPatternModelAdapter());
      }
      await AiDatasetService.initialize();

      if (task == _Tasks.syncPatterns) {
        await AiDatasetService().rebuildCacheFromRemote();
      }

      return true;
    } catch (e) {
      debugPrint('[BackgroundSync] Erro: $e');
      return false;
    }
  });
}

/// Serviço de sincronização periódica da base comunitária de padrões.
class BackgroundSyncService {
  static const String _uniqueNameSync = 'antigolpeia_sync_1';

  /// Inicializa o WorkManager e agenda a sincronização periódica.
  /// Chamar apenas uma vez em [main()].
  Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      _uniqueNameSync,
      _Tasks.syncPatterns,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );

    debugPrint('[BackgroundSync] Sync periódico agendado (12h).');
  }

  /// Força sincronização imediata — útil para testes ou primeiro uso.
  Future<void> syncNow() async {
    await Workmanager().registerOneOffTask(
      '${_uniqueNameSync}_now',
      _Tasks.syncPatterns,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Cancela todas as tarefas agendadas.
  Future<void> cancel() => Workmanager().cancelAll();
}
