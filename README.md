# AntiGolpeia

App Flutter (Android & iOS) para **alerta em tempo real de golpes digitais** via WhatsApp, SMS e Gmail, usando inteligência artificial.

> **Bundle ID:** `com.multiversodigital.antigolpeia`
> **Versão:** 1.0.2 | **Build:** 3

> **Importante:** o AntiGolpeia **não bloqueia nem impede** golpes. Ele lê a mensagem, avalia o risco com inteligência artificial e emite um **alerta**. A decisão final é sempre sua.

---

## Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| **Análise de mensagem** | Cole qualquer texto suspeito e receba relatório de risco com porcentagem, classificação e ação recomendada |
| **Monitor WhatsApp & Gmail** | Analisa notificações em tempo real, sem abrir o app |
| **Monitor de SMS** | Detecta links falsos e tentativas de golpe por SMS |
| **Verificação SIM Swap** | Consulta a API Twilio para detectar troca de chip recente |
| **Modo Privado** | Análise sem salvar no histórico |
| **Dashboard de Proteção** | Estatísticas de alertas por canal |
| **Estatísticas Inteligentes** | Gráficos de sunburst, barras e tendências de ameaças detectadas |
| **Histórico de Ameaças** | Todas as análises salvas com ícone de origem |
| **Alertas de Golpes** | Avisos sobre golpes circulando no momento |
| **Contatos Confiáveis** | Whitelist para evitar falsos alertas, com importação da agenda |
| **Denúncia às Autoridades** | Envio de relatório automático para autoridades |
| **Backup na Nuvem** | Backup e restauração de dados via Supabase |
| **AntiGolpeia Pro** | Plano pago com análises ilimitadas via RevenueCat |
| **Compartilhar Alerta** | Loop viral — avisa amigos e família sobre golpes detectados |
| **Tarefa em Foreground** | Monitoramento contínuo via `flutter_foreground_task` |

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| App | Flutter (Dart) — Material 3, tema escuro |
| Backend | Supabase Edge Functions (Deno / TypeScript) |
| IA | Claude Sonnet via Anthropic API |
| Banco de dados | Supabase (PostgreSQL) |
| Autenticação | Supabase Auth — login anônimo + Magic Link |
| SIM Swap | Twilio Lookup API v2 |
| Assinatura | RevenueCat + Google Play Billing |
| Notificações | notification_listener_service |
| SMS | telephony |
| Armazenamento local | Hive |
| Compartilhamento | share_plus |
| Gráficos | fl_chart |
| Agenda | flutter_contacts |
| Foreground task | flutter_foreground_task |

---

## Pré-requisitos

- Flutter SDK 3.x
- Android SDK (minSdk: 21, target: 34) ou Xcode 15+ para iOS
- Conta Supabase
- Chave Anthropic API
- Conta Twilio (para SIM Swap)
- Conta RevenueCat (para assinaturas)

---

## Configuração

### 1. Clone e instale dependências

```bash
git clone https://github.com/abreuretto72/antigolpeia.git
cd antigolpeia
flutter pub get
```

### 2. Variáveis de ambiente

Copie `.env.example` para `.env` e preencha os valores:

```bash
cp .env.example .env
```

| Variável | Descrição |
|---|---|
| `EXPO_PUBLIC_SUPABASE_URL` | URL do projeto Supabase |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Chave anônima do Supabase |
| `REVENUE_API_KEY` | Chave de produção do RevenueCat (sem `test_`) |

### 3. Variáveis de ambiente no Supabase

Configure em **Supabase → Edge Functions → Secrets**:

| Variável | Descrição |
|---|---|
| `ANTHROPIC_API_KEY` | Chave da API Anthropic (Claude) |
| `TWILIO_ACCOUNT_SID` | SID da conta Twilio |
| `TWILIO_AUTH_TOKEN` | Token da conta Twilio |

### 4. Deploy da Edge Function

```bash
supabase functions deploy analyze
supabase functions deploy check-sim-swap
```

### 5. Keystore Android (produção)

```bash
# Gere o keystore (apenas uma vez — guarde em local seguro)
keytool -genkey -v \
  -keystore android/app/antigolpeia.keystore \
  -alias antigolpeia \
  -keyalg RSA -keysize 2048 -validity 10000

# Copie o template e preencha com suas credenciais
cp android/key.properties.example android/key.properties
```

### 6. Execute o app

```bash
flutter run
```

---

## Build para produção

### Android — APK de distribuição

```bash
# APK release assinado
flutter build apk --release
```

Para distribuição via **Firebase App Distribution** (sem Play Store):

```powershell
# Windows — executa build + upload automaticamente
.\distribute.ps1
```

> Requer: Java 17 (`E:\androidstudio2021\jbr`), `firebase login` e `google-services.json` configurados.

### Android — AAB para Google Play

```bash
flutter build appbundle
```

### iOS (somente no Mac)

```bash
cd ios && pod install && cd ..
flutter build ipa
```

> Para builds iOS na nuvem sem Mac, use [Codemagic](https://codemagic.io).

---

## Distribuição Beta

A versão beta é distribuída via **Firebase App Distribution**, sem passar pelo Google Play Store.

- Link de instalação: `https://appdistribution.firebase.dev/i/13cedcc6bbeea64d`
- Para receber updates automáticos, instale o app pelo link acima.
- O Play Protect pode exibir aviso ao instalar APKs externos — basta confirmar a instalação.

---

## Permissões Android

| Permissão | Finalidade |
|---|---|
| `RECEIVE_SMS` / `READ_SMS` | Monitor de SMS |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Monitor de WhatsApp & Gmail |
| `READ_CONTACTS` | Importação de contatos confiáveis |
| `com.android.vending.BILLING` | Assinaturas Google Play (RevenueCat) |
| `FOREGROUND_SERVICE` | Monitoramento contínuo em background |

---

## Estrutura do projeto

```
lib/
├── main.dart                         # Bootstrap: Supabase, Hive, RevenueCat, monitores
├── pages/
│   ├── home_page.dart                # Tela principal — análise e monitores
│   ├── result_page.dart              # Relatório de risco com IA
│   ├── stats_page.dart               # Estatísticas e gráficos inteligentes
│   ├── history_page.dart             # Histórico de ameaças
│   ├── alerts_page.dart              # Alertas de golpes ativos
│   ├── help_page.dart                # Ajuda completa do app
│   ├── about_page.dart               # Sobre o AntiGolpeia
│   ├── account_page.dart             # Minha conta / exclusão de dados
│   ├── backup_settings_page.dart     # Backup na nuvem
│   ├── login_page.dart               # Login via Magic Link
│   ├── paywall_page.dart             # Tela de assinatura Pro
│   ├── privacy_policy_page.dart      # Política de Privacidade
│   └── terms_of_use_page.dart        # Termos de Uso
├── services/
│   ├── api_service.dart              # Integração Supabase
│   ├── notification_service.dart     # Monitor WhatsApp/Gmail
│   ├── sms_monitor_service.dart      # Monitor SMS
│   ├── gmail_service.dart            # Scanner Gmail
│   ├── activity_counter.dart         # Contador de atividades
│   ├── contacts_permission_service.dart  # Permissão de contatos
│   ├── foreground_task_service.dart  # Tarefa foreground contínua
│   ├── revenue_cat_service.dart      # Assinaturas RevenueCat
│   └── share_extension_handler.dart  # Receber texto de outros apps
└── features/
    ├── antigolpe/
    │   ├── constants/antigolpe_constants.dart
    │   └── services/whatsapp_monitor_service.dart
    └── antigolpeia/
        ├── core/utils/phone_utils.dart
        ├── data/models/
        │   ├── app_settings.dart
        │   ├── analysis_stats_model.dart
        │   ├── stats_models.dart
        │   ├── fraud_pattern_model.dart
        │   ├── whitelist_item.dart
        │   ├── blacklist_item.dart
        │   └── authority_report_model.dart
        ├── presentation/
        │   ├── dashboard_view.dart         # Dashboard de proteção
        │   ├── whitelist_view.dart         # Contatos confiáveis
        │   ├── contact_picker_view.dart    # Seletor de contatos da agenda
        │   └── widgets/
        │       ├── report_authority_card.dart
        │       └── sync_status_footer.dart
        └── services/
            ├── ai_dataset_service.dart         # Dataset local de padrões IA
            ├── authority_report_service.dart   # Denúncia às autoridades
            ├── background_sync_service.dart    # Sync em background
            ├── block_engine_service.dart       # Engine de bloqueio
            ├── cloud_backup_service.dart       # Backup na nuvem
            ├── guard_service.dart              # Whitelist / contatos confiáveis
            └── stats_intelligence_service.dart # Inteligência de estatísticas

supabase/
├── functions/
│   ├── analyze/index.ts              # Edge Function — análise com Claude AI
│   └── check-sim-swap/index.ts       # Edge Function — verificação SIM Swap
└── migrations/
    └── 20260405_community_fraud_patterns.sql  # Padrões comunitários de fraude

android/
├── app/build.gradle.kts              # Signing config + Firebase App Distribution
├── gradle.properties                 # kotlin.incremental=false (fix cross-drive cache)
└── app/src/main/AndroidManifest.xml

distribute.ps1                        # Script Windows: build APK + upload Firebase

docs/                                 # GitHub Pages — links públicos
├── index.html
├── politica-de-privacidade.html
└── termos-de-uso.html
```

---

## Páginas públicas (GitHub Pages)

| Página | URL |
|---|---|
| Política de Privacidade | `https://abreuretto72.github.io/antigolpeia/politica-de-privacidade.html` |
| Termos de Uso | `https://abreuretto72.github.io/antigolpeia/termos-de-uso.html` |

---

## Segurança e Privacidade

- Dados protegidos pela **LGPD (Lei nº 13.709/2018)**
- Conteúdo das mensagens é anonimizado antes do processamento
- Nenhum dado é vendido ou compartilhado com terceiros
- Keystore, credenciais e chaves Apple **nunca são commitados** (`.gitignore` configurado)
- RevenueCat só inicializa com chaves de produção (chaves `test_` são ignoradas)

---

## Licença

© 2026 Multiverso Digital. Todos os direitos reservados.
