# AntiGolpeia

App Flutter (Android & iOS) para detecção em tempo real de golpes digitais via WhatsApp, SMS e Gmail, usando inteligência artificial.

> **Bundle ID:** `com.multiversodigital.antigolpeia`
> **Versão:** 1.0.0 | **Build:** 1

---

## Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| **Análise de mensagem** | Cole qualquer texto suspeito e receba relatório de risco com porcentagem, classificação e ação recomendada |
| **Monitor WhatsApp & Gmail** | Analisa notificações em tempo real, sem abrir o app |
| **Monitor de SMS** | Detecta links falsos e tentativas de golpe por SMS |
| **Verificação SIM Swap** | Consulta a API Twilio para detectar troca de chip recente |
| **Modo Privado** | Análise sem salvar no histórico |
| **Dashboard de Proteção** | Estatísticas de golpes bloqueados por canal |
| **Histórico de Ameaças** | Todas as análises salvas com ícone de origem |
| **Alertas de Golpes** | Avisos sobre golpes circulando no momento |
| **Contatos Confiáveis** | Whitelist para evitar falsos alertas |
| **Denúncia às Autoridades** | Envio de relatório automático para autoridades |
| **Backup na Nuvem** | Backup e restauração de dados via Supabase |
| **AntiGolpeia Pro** | Plano pago com análises ilimitadas via RevenueCat |
| **Compartilhar Alerta** | Loop viral — avisa amigos e família sobre golpes detectados |

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| App | Flutter (Dart) — Material 3, tema escuro |
| Backend | Supabase Edge Functions (Deno / TypeScript) |
| IA | Claude Sonnet via Anthropic API |
| Banco de dados | Supabase (PostgreSQL) |
| Autenticação | Supabase Auth — Magic Link |
| SIM Swap | Twilio Lookup API v2 |
| Assinatura | RevenueCat + Google Play Billing |
| Notificações | notification_listener_service |
| SMS | telephony |
| Armazenamento local | Hive |
| Compartilhamento | share_plus |

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

### 2. Variáveis de ambiente no Supabase

Configure em **Supabase → Edge Functions → Secrets**:

| Variável | Descrição |
|---|---|
| `ANTHROPIC_API_KEY` | Chave da API Anthropic (Claude) |
| `TWILIO_ACCOUNT_SID` | SID da conta Twilio |
| `TWILIO_AUTH_TOKEN` | Token da conta Twilio |

### 3. Deploy da Edge Function

```bash
supabase functions deploy analyze
```

### 4. Keystore Android (produção)

```bash
# Gere o keystore (apenas uma vez — guarde em local seguro)
keytool -genkey -v \
  -keystore android/app/antigolpeia.keystore \
  -alias antigolpeia \
  -keyalg RSA -keysize 2048 -validity 10000

# Copie o template e preencha com suas credenciais
cp android/key.properties.example android/key.properties
```

### 5. Execute o app

```bash
flutter run
```

---

## Build para produção

### Android (APK / AAB)

```bash
# AAB para Google Play
flutter build appbundle

# APK para testes
flutter build apk --split-per-abi
```

### iOS (somente no Mac)

```bash
cd ios && pod install && cd ..
flutter build ipa
```

> Para builds iOS na nuvem sem Mac, use [Codemagic](https://codemagic.io).

---

## Permissões Android

| Permissão | Finalidade |
|---|---|
| `RECEIVE_SMS` / `READ_SMS` | Monitor de SMS |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Monitor de WhatsApp & Gmail |
| `com.android.vending.BILLING` | Assinaturas Google Play (RevenueCat) |

---

## Estrutura do projeto

```
lib/
├── main.dart
├── pages/
│   ├── home_page.dart            # Tela principal — análise e monitores
│   ├── result_page.dart          # Relatório de risco com IA
│   ├── history_page.dart         # Histórico de ameaças
│   ├── alerts_page.dart          # Alertas de golpes ativos
│   ├── help_page.dart            # Ajuda completa do app
│   ├── about_page.dart           # Sobre o AntiGolpeia
│   ├── account_page.dart         # Minha conta / exclusão de dados
│   ├── backup_settings_page.dart # Backup na nuvem
│   ├── login_page.dart           # Login via Magic Link
│   ├── paywall_page.dart         # Tela de assinatura Pro
│   ├── privacy_policy_page.dart  # Política de Privacidade
│   └── terms_of_use_page.dart    # Termos de Uso
├── services/
│   ├── api_service.dart              # Integração Supabase
│   ├── notification_service.dart     # Monitor WhatsApp/Gmail
│   ├── sms_monitor_service.dart      # Monitor SMS
│   └── gmail_service.dart            # Scanner Gmail
└── features/
    ├── antigolpe/
    │   ├── constants/antigolpe_constants.dart
    │   └── services/twilio_service.dart   # Verificação SIM Swap
    └── antigolpeia/
        ├── data/models/app_settings.dart
        ├── presentation/
        │   ├── dashboard_view.dart         # Dashboard de proteção
        │   ├── whitelist_view.dart         # Contatos confiáveis
        │   └── widgets/
        │       ├── report_authority_card.dart
        │       └── sync_status_footer.dart
        └── services/
            ├── authority_report_service.dart  # Denúncia às autoridades
            ├── cloud_backup_service.dart      # Backup na nuvem
            ├── guard_service.dart             # Whitelist / contatos confiáveis
            └── stats_service.dart             # Estatísticas do dashboard

supabase/functions/analyze/
└── index.ts                  # Edge Function — análise com Claude AI

android/
├── app/build.gradle.kts      # Signing config com keystore
├── key.properties.example    # Template de credenciais (não commitar key.properties)
└── app/src/main/
    ├── AndroidManifest.xml
    └── kotlin/com/multiversodigital/antigolpeia/

docs/                         # GitHub Pages — links públicos
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
- Keystore e credenciais **nunca são commitados** (`.gitignore` configurado)

---

## Licença

© 2025 Multiverso Digital. Todos os direitos reservados.
