import 'package:flutter/material.dart';

class AntiGolpeConstants {
  // Package Names
  static const String whatsappPackage = "com.whatsapp";

  // Identidade Visual AntiGolpe 2026
  static const Color colorSafe = Color(0xFF10AC84); // Verde Seguro
  static const Color colorRisk = Color(0xFFF44336); // Vermelho Risco
  static const Color colorAudit = Color(0xFFBDC3C7); // Cinza Auditoria

  // Chaves de tradução — monitor
  static const String keyMonitoringActive = 'antigolpe_monitoring_active';
  static const String keyMonitoringDesc = 'antigolpe_monitoring_desc';
  static const String keyLogFraud = 'antigolpe_log_fraud';
  static const String keyLogSafe = 'antigolpe_log_safe';

  // Chaves de tradução — IA comunitária
  static const String keyIaScanning = 'antigolpeia_ia_scanning';
  static const String keyIaConfirmed = 'antigolpeia_ia_confirmed';
  static const String keyIaContribute = 'antigolpeia_ia_contribute';
  static const String keyIaPatternMatch = 'antigolpeia_ia_pattern_match';
  static const String keyStatsSyncUpdated = 'antigolpeia_ia_updated';
  static const String keyStatsDashboardTitle = 'antigolpeia_stats_title';
  static const String keyStatsBlockedLabel = 'antigolpeia_stats_blocked_label';
  static const String keyAiAnalysis = 'antigolpeia_ai_analysis';

  // Chaves de tradução — whitelist
  static const String keyWhitelistTitle = 'antigolpeia_whitelist_title';
  static const String keyWhitelistEmpty = 'antigolpeia_whitelist_empty';

  // Chaves de tradução — motivos de risco
  static const String keyReasonVoip = 'antigolpeia_reason_voip';
  static const String keyReasonLink = 'antigolpeia_reason_link';
  static const String keyReasonCommunity = 'antigolpeia_reason_community';
  static const String keyReasonPattern = 'antigolpeia_reason_pattern';

  // Chaves de tradução — autenticação e backup
  static const String keyAuthError = 'antigolpeia_auth_error';
  static const String keyBackupNotFound = 'antigolpeia_backup_not_found';
  static const String keySupabaseOnline = 'antigolpeia_supabase_online';
  static const String keySupabaseOffline = 'antigolpeia_supabase_offline';
  static const String keyBtnBackup = 'antigolpeia_btn_backup';
  static const String keyBtnRestore = 'antigolpeia_btn_restore';
  static const String keyBackupTitle = 'antigolpeia_backup_title';

  // Chaves de tradução — bloqueio
  static const String keyBlockConfirmTitle = 'antigolpeia_block_confirm_title';
  static const String keyBtnBlockNow = 'antigolpeia_btn_block_now';

  // Chaves de tradução — permissão de contatos
  static const String keyContactsPermissionTitle = 'Acesso aos Contatos';
  static const String keyContactsPermissionIosInfo =
      'No iPhone, precisamos disto para identificar seus contatos seguros.';
  static const String keyContactsPermissionAndroidInfo =
      'No Android, isso permite que o AntiGolpeia bloqueie SMS falsos.';
  static const String keyContactsPermissionDenied =
      'Permissão negada. Abra Ajustes e permita o acesso aos contatos.';

  // Chaves de tradução — seletor de contatos
  static const String keyContactsPickerTitle = 'Selecione contatos confiáveis';
  static const String keyContactsPickerSearch = 'Buscar contato...';
  static const String keyContactsPickerLoading = 'Carregando contatos...';
  static const String keyContactsPickerError = 'Não foi possível carregar os contatos.';
  static const String keyContactsPickerEmpty = 'Nenhum contato encontrado.';
  static const String keyContactsPickerConfirm = 'Adicionar confiáveis';
  static const String keyContactsPickerConfirmEmpty = 'Selecione ao menos um contato';
  static const String keyContactsPickerAdded = 'contato(s) adicionado(s) à lista de confiança.';

  // Chaves de tradução — configurações
  static const String keySettingsSoundTitle = 'antigolpeia_settings_sound_title';
  static const String keySettingsHaptic = 'antigolpeia_settings_haptic';

  // Chaves de tradução — denúncia a autoridades
  static const String keyReportTitle = 'antigolpeia_report_title';
  static const String keyReportSubtitle = 'antigolpeia_report_subtitle';
}
