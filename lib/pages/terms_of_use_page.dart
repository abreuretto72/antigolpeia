import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header('Termos de Uso — AntiGolpeia'),
        _Body(
          'Última atualização: abril de 2026\n\n'
          'Ao instalar ou utilizar o AntiGolpeia, você ("Usuário") concorda com os '
          'presentes Termos de Uso. Leia atentamente antes de prosseguir.',
        ),

        _Section('1. Descrição do Serviço'),
        _Body(
          'O AntiGolpeia é um aplicativo Android desenvolvido pela Multiverso Digital '
          'que utiliza inteligência artificial para analisar mensagens suspeitas e alertar '
          'o usuário sobre possíveis tentativas de fraude (golpes de Pix, SIM Swap, '
          'phishing, engenharia social, entre outros).',
        ),

        _Section('2. Uso Permitido'),
        _Body(
          'O aplicativo destina-se exclusivamente ao uso pessoal e não comercial. '
          'É expressamente proibido:\n\n'
          '• Utilizar o AntiGolpeia para fins ilegais ou fraudulentos.\n'
          '• Tentar reverter a engenharia do aplicativo, extrair código-fonte ou '
          'descompilar seus componentes.\n'
          '• Automatizar o envio de mensagens ao sistema de análise para fins '
          'diferentes da proteção pessoal.\n'
          '• Submeter intencionalmente conteúdo falso à base comunitária de padrões '
          'de fraude com o objetivo de prejudicar outros usuários.',
        ),

        _Section('3. Limitação de Responsabilidade'),
        _Body(
          'O AntiGolpeia é uma ferramenta de auxílio à decisão, não uma garantia '
          'absoluta de segurança. A análise de risco é realizada por modelos de '
          'inteligência artificial sujeitos a erros (falsos positivos e falsos '
          'negativos). O Usuário é o único responsável pelas decisões tomadas com '
          'base nos relatórios gerados pelo aplicativo.\n\n'
          'A Multiverso Digital não se responsabiliza por:\n\n'
          '• Perdas financeiras decorrentes de golpes não detectados pelo aplicativo.\n'
          '• Decisões tomadas com base exclusiva nas análises do app.\n'
          '• Indisponibilidade temporária do serviço por razões técnicas.\n'
          '• Danos causados por uso indevido do aplicativo pelo Usuário.',
        ),

        _Section('4. Conteúdo do Usuário'),
        _Body(
          'Ao enviar mensagens para análise ou contribuir com padrões para a base '
          'comunitária, o Usuário declara:\n\n'
          '• Ter o direito de compartilhar o conteúdo submetido.\n'
          '• Estar ciente de que o conteúdo será anonimizado (remoção de PII) antes '
          'de qualquer armazenamento ou processamento externo.\n'
          '• Conceder à Multiverso Digital licença não exclusiva para utilizar os '
          'padrões anonimizados no aprimoramento do banco comunitário de fraudes.',
        ),

        _Section('5. Propriedade Intelectual'),
        _Body(
          'Todo o código-fonte, design, marca, logotipo e conteúdo do AntiGolpeia '
          'são de propriedade exclusiva da Multiverso Digital e protegidos pelas '
          'leis de propriedade intelectual vigentes no Brasil. É vedada a reprodução '
          'total ou parcial sem autorização prévia e por escrito.',
        ),

        _Section('6. Privacidade'),
        _Body(
          'O tratamento de dados pessoais é regido pela nossa Política de Privacidade, '
          'disponível no próprio aplicativo em Menu → Política de Privacidade, '
          'em conformidade com a LGPD (Lei nº 13.709/2018).',
        ),

        _Section('7. Atualizações e Descontinuação'),
        _Body(
          'A Multiverso Digital reserva-se o direito de:\n\n'
          '• Atualizar, modificar ou descontinuar funcionalidades a qualquer momento.\n'
          '• Encerrar o serviço mediante aviso prévio de 30 dias.\n'
          '• Alterar estes Termos, comunicando o Usuário pelo próprio aplicativo.',
        ),

        _Section('8. Legislação Aplicável'),
        _Body(
          'Estes Termos são regidos pela legislação brasileira. Fica eleito o foro '
          'da comarca de São Paulo/SP para dirimir quaisquer controvérsias, '
          'com renúncia a qualquer outro, por mais privilegiado que seja.',
        ),

        _Section('9. Contato'),
        _Body(
          'Multiverso Digital\n'
          'E-mail: contato@multiversodigital.com.br\n\n'
          'Dúvidas, sugestões ou solicitações relacionadas a estes Termos devem '
          'ser enviadas para o e-mail acima.',
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
