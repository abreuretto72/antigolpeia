import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header('Política de Privacidade — AntiGolpeia'),
        _Body(
          'Última atualização: abril de 2026\n\n'
          'A Multiverso Digital ("nós") desenvolveu o AntiGolpeia com o compromisso de '
          'proteger sua privacidade e estar em conformidade com a Lei Geral de Proteção de '
          'Dados (LGPD — Lei nº 13.709/2018). Esta política explica quais dados coletamos, '
          'como os usamos e quais são seus direitos.',
        ),

        _Section('1. Dados Coletados'),
        _Body(
          '• Conteúdo analisado: mensagens de texto coladas manualmente ou recebidas via '
          'monitor automático (WhatsApp, SMS, Gmail) são enviadas ao servidor para análise '
          'de risco. Antes do envio, todos os dados pessoais identificáveis (CPF, telefone, '
          'nome, e-mail) são substituídos por marcadores genéricos (técnica de anonimização '
          'de PII).\n\n'
          '• Conta anônima: ao iniciar o app pela primeira vez, criamos automaticamente uma '
          'conta anônima no Supabase para salvar seu histórico e backup. Nenhum dado '
          'pessoal é exigido.\n\n'
          '• Whitelist e Blacklist: os números que você adiciona como confiáveis ou '
          'bloqueados ficam armazenados localmente no dispositivo (Hive) e, se você '
          'ativar o backup, são cifrados e armazenados na nuvem vinculados ao seu ID anônimo.\n\n'
          '• Estatísticas de uso: coletamos de forma agregada e não identificável o número '
          'de análises realizadas, classificação de risco e canal de origem (SMS, WhatsApp '
          'etc.) para melhorar a base comunitária de padrões de fraude.',
        ),

        _Section('2. Finalidade do Tratamento'),
        _Body(
          '• Analisar mensagens suspeitas e exibir relatório de risco ao usuário.\n'
          '• Manter e aprimorar o banco comunitário de padrões de golpes.\n'
          '• Sincronizar backup criptografado de listas de contatos na nuvem.\n'
          '• Enviar denúncias às autoridades competentes quando solicitado pelo usuário.\n'
          '• Cumprir obrigações legais.',
        ),

        _Section('3. Compartilhamento de Dados'),
        _Body(
          'Não vendemos nem alugamos seus dados a terceiros. O conteúdo anonimizado '
          'das análises pode ser compartilhado de forma agregada com:\n\n'
          '• Supabase (infraestrutura de banco de dados e autenticação — EUA, com '
          'cláusulas contratuais padrão de adequação à LGPD).\n'
          '• Anthropic (processamento de linguagem natural para análise de risco — '
          'os textos enviados são anonimizados antes da transmissão).\n'
          '• Autoridades públicas, quando o próprio usuário acionar a função '
          '"Denunciar às Autoridades".',
        ),

        _Section('4. Retenção de Dados'),
        _Body(
          '• Histórico de análises: mantido indefinidamente vinculado à conta anônima, '
          'podendo ser excluído a qualquer momento pelo usuário.\n'
          '• Backup na nuvem: excluído imediatamente quando a conta é removida.\n'
          '• Padrões de fraude anonimizados contribuídos à base comunitária: '
          'retidos por prazo indeterminado para fins de segurança pública.',
        ),

        _Section('5. Seus Direitos (LGPD art. 18)'),
        _Body(
          'Você pode, a qualquer momento:\n\n'
          '• Confirmar a existência de tratamento de seus dados.\n'
          '• Acessar, corrigir ou portar seus dados.\n'
          '• Solicitar a anonimização, bloqueio ou eliminação de dados desnecessários.\n'
          '• Revogar o consentimento.\n'
          '• Solicitar a exclusão completa da conta.\n\n'
          'Para exercer seus direitos, envie e-mail para: '
          'contato@multiversodigital.com.br',
        ),

        _Section('6. Segurança'),
        _Body(
          'Adotamos medidas técnicas e organizacionais para proteger seus dados:\n\n'
          '• Comunicação exclusivamente via HTTPS/TLS.\n'
          '• Anonimização de PII antes de qualquer transmissão externa.\n'
          '• Row Level Security (RLS) no banco de dados: cada usuário acessa '
          'exclusivamente seus próprios dados.\n'
          '• Armazenamento local criptografado via Hive.',
        ),

        _Section('7. Dados de Menores'),
        _Body(
          'O AntiGolpeia não é direcionado a menores de 18 anos. Não coletamos '
          'intencionalmente dados de crianças ou adolescentes. Caso identifiquemos '
          'que dados de menores foram coletados inadvertidamente, procederemos à '
          'exclusão imediata.',
        ),

        _Section('8. Alterações nesta Política'),
        _Body(
          'Podemos atualizar esta Política periodicamente. Notificaremos você por '
          'meio de aviso no próprio aplicativo. O uso continuado após a notificação '
          'implica aceite das alterações.',
        ),

        _Section('9. Contato'),
        _Body(
          'Multiverso Digital\n'
          'E-mail: contato@multiversodigital.com.br\n\n'
          'Para questões relacionadas à LGPD, este endereço funciona também como '
          'canal do Encarregado de Dados (DPO).',
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, height: 1.3)),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.6));
  }
}
