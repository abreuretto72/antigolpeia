import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Singleton que encapsula toda a lógica do RevenueCat.
///
/// Fluxo de uso:
///   1. Chamar [RevenueCatService.initialize] antes do runApp.
///   2. Chamar [linkUser] logo após a autenticação Supabase.
///   3. Ouvir [proNotifier] para reações em tempo real a compras/cancelamentos.
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// ID do entitlement configurado no dashboard do RevenueCat.
  static const String entitlementId = 'AntiGolpeIA Pro';

  /// Notifica toda a UI quando o status Pro muda (compra, restauração, expiração).
  final ValueNotifier<bool> proNotifier = ValueNotifier(false);

  // ── Inicialização ────────────────────────────────────────────────────────

  static Future<void> initialize(String apiKey) async {
    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.error,
    );

    // Configuração com purchasesAreCompletedByRevenueCat — padrão recomendado.
    // RevenueCat finaliza as transações automaticamente.
    final PurchasesConfiguration config;
    if (!kIsWeb && Platform.isAndroid) {
      // Suporte ao Amazon Appstore via dart-define: --dart-define=AMAZON=true
      const useAmazon = bool.fromEnvironment('amazon', defaultValue: false);
      config = useAmazon
          ? (AmazonConfiguration(apiKey)
            ..appUserID = null
            ..purchasesAreCompletedBy =
                const PurchasesAreCompletedByRevenueCat())
          : (PurchasesConfiguration(apiKey)
            ..appUserID = null
            ..purchasesAreCompletedBy =
                const PurchasesAreCompletedByRevenueCat());
    } else {
      config = PurchasesConfiguration(apiKey)
        ..appUserID = null
        ..purchasesAreCompletedBy =
            const PurchasesAreCompletedByRevenueCat();
    }

    await Purchases.configure(config);

    // Registra o listener global — reage a qualquer mudança de estado:
    // compra, restauração, renovação, expiração.
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      final active =
          customerInfo.entitlements.active.containsKey(entitlementId);
      instance.proNotifier.value = active;
      debugPrint('[RC] CustomerInfo atualizado. Pro: $active');
    });

    // Lê o estado inicial imediatamente após configurar.
    try {
      final info = await Purchases.getCustomerInfo();
      instance.proNotifier.value =
          info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('[RC] Erro ao ler CustomerInfo inicial: $e');
    }
  }

  // ── Identificação do usuário ─────────────────────────────────────────────

  /// Vincula o usuário Supabase ao RevenueCat.
  /// Mantém histórico de compras mesmo após reinstalação.
  Future<void> linkUser(String supabaseUserId) async {
    try {
      final result = await Purchases.logIn(supabaseUserId);
      proNotifier.value = result.customerInfo.entitlements.active
          .containsKey(entitlementId);
      debugPrint('[RC] Usuário vinculado: $supabaseUserId');
    } catch (e) {
      debugPrint('[RC] Erro ao vincular usuário: $e');
    }
  }

  /// Desvincula o usuário ao fazer logout (volta para ID anônimo RC).
  Future<void> unlinkUser() async {
    try {
      final info = await Purchases.logOut();
      proNotifier.value =
          info.entitlements.active.containsKey(entitlementId);
      debugPrint('[RC] Usuário desvinculado.');
    } catch (e) {
      debugPrint('[RC] Erro ao deslogar: $e');
    }
  }

  /// Retorna o App User ID atual do RevenueCat.
  Future<String> get appUserId async => Purchases.appUserID;

  // ── Entitlement ──────────────────────────────────────────────────────────

  /// Retorna `true` se o usuário tem "AntiGolpeIA Pro" ativo.
  /// Use [proNotifier] para reações reativas em vez de chamar isso repetidamente.
  Future<bool> get isPro async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.active.containsKey(entitlementId);
      proNotifier.value = active;
      return active;
    } catch (e) {
      debugPrint('[RC] Erro ao verificar entitlement: $e');
      return proNotifier.value; // fallback ao último estado conhecido
    }
  }

  /// Retorna as informações completas do cliente.
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[RC] Erro ao obter CustomerInfo: $e');
      return null;
    }
  }

  // ── Offerings ────────────────────────────────────────────────────────────

  /// Retorna o offering atual configurado no dashboard do RevenueCat.
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint('[RC] Erro ao obter offering: $e');
      return null;
    }
  }

  // ── Compras ──────────────────────────────────────────────────────────────

  /// Compra um pacote específico (monthly / yearly / lifetime).
  Future<CustomerInfo?> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      proNotifier.value =
          result.customerInfo.entitlements.active.containsKey(entitlementId);
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RC] Erro na compra: $e');
      }
      return null;
    } catch (e) {
      debugPrint('[RC] Erro inesperado na compra: $e');
      return null;
    }
  }

  /// Restaura compras anteriores — obrigatório nas lojas.
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      proNotifier.value =
          info.entitlements.active.containsKey(entitlementId);
      return info;
    } catch (e) {
      debugPrint('[RC] Erro ao restaurar: $e');
      return null;
    }
  }
}
