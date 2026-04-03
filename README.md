# AntiGolpe IA

App Android para detecção em tempo real de golpes digitais via WhatsApp, SMS e Gmail, usando inteligência artificial.

## Funcionalidades

- **Análise de texto** — cole qualquer mensagem suspeita e receba uma avaliação de risco em segundos
- **Monitor de WhatsApp & Gmail** — analisa automaticamente mensagens recebidas via notificações
- **Monitor de SMS** — detecta links encurtados e conteúdo suspeito em SMS recebidos
- **Verificação de SIM Swap** — consulta a API Twilio para detectar se um número trocou de chip recentemente
- **Histórico de ameaças** — todas as análises salvas com ícone de origem (WhatsApp, SMS, E-mail, Texto)
- **Alerta imediato** — notificação na tela quando risco > 50%

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| App | Flutter (Dart) |
| Backend | Supabase Edge Functions (Deno) |
| IA | Claude Haiku via Anthropic API |
| Banco de dados | Supabase (PostgreSQL) |
| SIM Swap | Twilio Lookup API v2 |
| Notificações | notification_listener_service |
| SMS | telephony |

## Pré-requisitos

- Flutter SDK 3.x
- Android SDK (target: Android 14+)
- Conta Supabase
- Chave Anthropic API
- Conta Twilio (opcional, para SIM Swap)

## Configuração

1. Clone o repositório:
```bash
git clone https://github.com/abreuretto72/antigolpeia.git
cd antigolpeia
```

2. Crie o arquivo `.env` na raiz com as credenciais:
```env
TWILIO_ACCOUNT_SID=seu_sid
TWILIO_AUTH_TOKEN=seu_token
TWILIO_LOOKUP_URL=https://lookups.twilio.com/v2/PhoneNumbers
EXPO_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=sua_anon_key
ANTHROPIC_API_KEY=sua_chave_anthropic
```

3. Instale as dependências:
```bash
flutter pub get
```

4. Deploy da Edge Function no Supabase:
```bash
supabase functions deploy analyze
supabase secrets set ANTHROPIC_API_KEY=sua_chave
```

5. Execute o app:
```bash
flutter run
```

## Permissões Android necessárias

- `RECEIVE_SMS` / `READ_SMS` — monitor de SMS
- Acesso a notificações — monitor de WhatsApp/Gmail
  - Configurações → Apps → Acesso especial → Acesso a notificações → AntiGolpe IA

## Estrutura do projeto

```
lib/
├── main.dart
├── pages/
│   ├── home_page.dart        # Tela principal
│   ├── result_page.dart      # Relatório de risco
│   ├── history_page.dart     # Histórico de análises
│   ├── alerts_page.dart      # Alertas de golpes ativos
│   └── paywall_page.dart
├── services/
│   ├── api_service.dart          # Integração Supabase
│   ├── notification_service.dart # Monitor WhatsApp/Gmail
│   ├── sms_monitor_service.dart  # Monitor SMS
│   └── gmail_service.dart        # Scanner Gmail
└── features/antigolpe/services/
    ├── twilio_service.dart        # Verificação SIM Swap
    └── whatsapp_monitor_service.dart

supabase/functions/analyze/
└── index.ts                  # Edge Function com Claude
```

## Variáveis de ambiente no Supabase

Configure no painel do Supabase → Edge Functions → Secrets:

| Variável | Descrição |
|----------|-----------|
| `ANTHROPIC_API_KEY` | Chave da API Anthropic |

O modelo de IA é configurável via tabela `app_settings` no banco:
```sql
INSERT INTO app_settings (key, value) VALUES ('ai_model', 'claude-haiku-4-5-20251001');
```
