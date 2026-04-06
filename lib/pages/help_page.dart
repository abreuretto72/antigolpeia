import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/antigolpe/constants/antigolpe_constants.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: const [
          _IntroCard(),
          SizedBox(height: 16),
          _SectionHeader('COMO USAR O APP'),
          SizedBox(height: 8),
          _HelpTile(
            icon: Icons.search,
            iconColor: Colors.deepPurpleAccent,
            title: 'Como analisar uma mensagem?',
            body: 'Na tela inicial, cole o texto da mensagem suspeita no campo '
                'de texto — pode ser uma mensagem de WhatsApp, SMS, e-mail ou '
                'qualquer texto que você desconfiou.\n\n'
                'Toque em "Analisar risco" e aguarde alguns segundos. O app '
                'vai gerar um relatório com:\n\n'
                '• Porcentagem de risco (0% a 100%) — quanto maior, mais perigoso.\n'
                '• Classificação: "Seguro", "Suspeito" ou "Golpe".\n'
                '• Tipo de golpe identificado (ex: falso suporte bancário, Pix falso).\n'
                '• Explicação em linguagem simples do por que a mensagem é perigosa.\n'
                '• Sinais de alerta encontrados no texto.\n'
                '• Ação imediata recomendada para você se proteger.\n\n'
                'Dica: na dúvida, analise antes de clicar em qualquer link ou '
                'fazer qualquer Pix.',
          ),
          _HelpTile(
            icon: Icons.visibility_off_outlined,
            iconColor: Colors.deepPurpleAccent,
            title: 'O que é o Modo Privado?',
            body: 'Quando você ativa o Modo Privado (o botão fica logo abaixo '
                'do botão "Analisar risco"), a análise é feita normalmente, mas '
                'o resultado não é salvo no seu histórico nem na nuvem.\n\n'
                'Use quando quiser analisar uma mensagem sem deixar registro. '
                'A análise tem a mesma qualidade — só não fica gravada.\n\n'
                'Depois de analisar, você pode desativar o Modo Privado para que '
                'as próximas análises voltem a ser salvas.',
          ),
          _HelpTile(
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.green,
            title: 'O que é o monitor automático de WhatsApp e Gmail?',
            body: 'O monitor fica de olho nas suas notificações de WhatsApp e '
                'Gmail. Quando uma mensagem nova chega, o app analisa '
                'automaticamente se parece golpe — sem você precisar fazer nada.\n\n'
                'Como ativar: na tela inicial, toque em "ATIVAR" no card '
                '"Monitor de WhatsApp & Gmail". O celular vai pedir permissão '
                'para ler notificações.\n\n'
                'Privacidade: o app lê apenas o texto da notificação para '
                'analisar. Não acessa suas conversas completas, fotos, áudios '
                'ou contatos. Tudo segue a LGPD.\n\n'
                'Se detectar um golpe, você recebe um alerta imediatamente, '
                'antes de clicar em qualquer link.',
          ),
          _HelpTile(
            icon: Icons.sms_outlined,
            iconColor: Colors.green,
            title: 'Como funciona a proteção de SMS?',
            body: 'O monitor de SMS analisa as mensagens de texto que chegam '
                'no seu celular. Muitos golpes usam SMS para enviar links '
                'falsos de bancos, cobranças inventadas e códigos roubados.\n\n'
                'Como ativar: na tela inicial, toque em "ATIVAR" no card '
                '"Monitor de SMS".\n\n'
                'O app detecta automaticamente:\n'
                '• Links falsos disfarçados de bancos ou lojas.\n'
                '• Mensagens de "centrais de segurança" falsas.\n'
                '• Tentativas de roubo de códigos de verificação.\n\n'
                'Quando um SMS suspeito chega, você é avisado na hora.',
          ),
          _HelpTile(
            icon: Icons.phone_in_talk_outlined,
            iconColor: Colors.orangeAccent,
            title: 'O que é verificar número (SIM Swap)?',
            body: 'O golpe de SIM Swap acontece quando um criminoso convence a '
                'operadora a transferir o seu número para um chip novo. Com '
                'isso, ele passa a receber seus códigos de banco e WhatsApp.\n\n'
                'Com essa função, você digita o número de quem entrou em '
                'contato e o app verifica se o chip daquele número foi trocado '
                'recentemente.\n\n'
                '• Chip trocado recentemente: risco alto. Não faça Pix nem '
                'envie dados pessoais. Confirme a identidade por videochamada.\n'
                '• Sem troca recente: o número parece normal, mas isso não '
                'garante que a pessoa é quem diz ser.\n\n'
                'Para usar, toque em "Verificar número (SIM Swap)" na tela '
                'inicial e digite o número com DDD.',
          ),
          SizedBox(height: 16),
          _SectionHeader('RECURSOS DO APP'),
          SizedBox(height: 8),
          _HelpTile(
            icon: Icons.bar_chart_rounded,
            iconColor: AntiGolpeConstants.colorSafe,
            title: 'O que é o Dashboard de Proteção?',
            body: 'O Dashboard mostra um resumo de toda a sua atividade de '
                'proteção: quantas mensagens você já analisou, quantos golpes '
                'foram detectados e seu nível de proteção geral.\n\n'
                'É como um painel de controle que mostra o quanto o app está '
                'trabalhando para te proteger.\n\n'
                'Acesse pelo menu lateral (ícone de três linhas no canto '
                'superior esquerdo da tela inicial).',
          ),
          _HelpTile(
            icon: Icons.history,
            iconColor: Colors.blueAccent,
            title: 'Onde vejo as análises anteriores?',
            body: 'Todas as mensagens que você analisou ficam salvas no '
                'Histórico de Ameaças — exceto as que foram analisadas no '
                'Modo Privado.\n\n'
                'Para acessar, toque no ícone de relógio no canto superior '
                'direito da tela inicial, ou pelo menu lateral em '
                '"Histórico de Ameaças".\n\n'
                'Lá você pode rever o resultado de cada análise, incluindo a '
                'porcentagem de risco e a classificação.',
          ),
          _HelpTile(
            icon: Icons.verified_user_outlined,
            iconColor: Colors.tealAccent,
            title: 'Como funciona a lista de contatos confiáveis?',
            body: 'Você pode adicionar números de telefone que são confiáveis '
                '— como familiares e amigos próximos — na lista de '
                'Contatos Confiáveis.\n\n'
                'Quando o monitor automático recebe uma mensagem de um número '
                'da lista, ele não dispara alerta. Isso evita falsos alarmes '
                'com pessoas que você já conhece.\n\n'
                'Para adicionar, vá no menu lateral e toque em '
                '"Contatos Confiáveis".\n\n'
                'Importante: só adicione números de pessoas que você realmente '
                'conhece. Se o celular de alguém for clonado, o monitor não '
                'vai alertar você.',
          ),
          _HelpTile(
            icon: Icons.verified_user_outlined,
            iconColor: Colors.tealAccent,
            title: 'Como os Contatos Confiáveis protegem nas análises automáticas?',
            body: 'Quando uma mensagem chega pelo WhatsApp, Gmail ou SMS, o app '
                'verifica primeiro se o remetente está na sua lista de '
                'Contatos Confiáveis — antes de enviar qualquer coisa para a IA.\n\n'
                'Se for um contato confiável, você vê um aviso verde:\n'
                '"[Nome] está nos Contatos Confiáveis — mensagem liberada."\n\n'
                'A mensagem não é analisada pela IA, economizando processamento '
                'e garantindo que pessoas de confiança nunca disparem alertas falsos.\n\n'
                'Como funciona a verificação por canal:\n\n'
                '• SMS: compara pelo número de telefone — a correspondência é '
                'exata e independe de como o contato está salvo na agenda.\n\n'
                '• WhatsApp e Gmail: o sistema recebe apenas o nome exibido na '
                'notificação (o WhatsApp não fornece o número ao app). Por isso, '
                'o nome cadastrado nos Contatos Confiáveis deve ser idêntico ao '
                'nome salvo na sua agenda. Se o número não estiver salvo na '
                'agenda, o WhatsApp exibe o número bruto na notificação — nesse '
                'caso a verificação é feita pelo número automaticamente.\n\n'
                'Dica: para máxima proteção no WhatsApp, salve o contato na '
                'agenda com o mesmo nome que você usou nos Contatos Confiáveis.',
          ),
          _HelpTile(
            icon: Icons.campaign_outlined,
            iconColor: Colors.orangeAccent,
            title: 'O que são os Alertas de Golpes?',
            body: 'A seção de Alertas mostra golpes que estão circulando no '
                'momento — avisos baseados em denúncias da comunidade e em '
                'padrões detectados pela inteligência artificial.\n\n'
                'Por exemplo: se várias pessoas analisam mensagens parecidas '
                'sobre um golpe do Pix com QR Code, o app cria um alerta para '
                'avisar todo mundo.\n\n'
                'Acesse pelo menu lateral em "Alertas de Golpes" ou pelo '
                'banner vermelho na tela inicial.\n\n'
                'Fique de olho — os alertas ajudam você a se proteger mesmo '
                'antes de receber a mensagem golpista.',
          ),
          _HelpTile(
            icon: Icons.gavel_rounded,
            iconColor: AntiGolpeConstants.colorSafe,
            title: 'Como denunciar um golpe às autoridades?',
            body: 'Quando o app identifica uma mensagem com risco acima de '
                '60%, a tela de resultado mostra um botão verde "DENUNCIAR".\n\n'
                'Ao tocar, o app registra automaticamente um relatório com os '
                'dados da análise para as autoridades competentes.\n\n'
                'Denunciar ajuda a proteger outras pessoas. Quanto mais '
                'denúncias, mais rápido as autoridades conseguem agir contra '
                'os golpistas.\n\n'
                'Você também pode registrar um Boletim de Ocorrência online '
                'no site da Polícia Civil do seu estado.',
          ),
          _HelpTile(
            icon: Icons.cloud_sync_outlined,
            iconColor: Colors.white54,
            title: 'Como funciona o backup e as configurações?',
            body: 'No menu lateral, toque em "Backup & Configurações".\n\n'
                'Backup:\n'
                '• "Salvar na Nuvem" — faz uma cópia dos seus dados agora.\n'
                '• "Restaurar Dados" — recupera os dados do backup anterior. '
                'Útil ao trocar de celular ou reinstalar o app.\n\n'
                'Configurações:\n'
                '• Sons de alerta — ative ou desative o som quando um golpe '
                'é detectado.\n'
                '• Vibração — ative ou desative a vibração nos alertas.\n\n'
                'Seus backups são protegidos pela sua conta. Ninguém mais tem '
                'acesso.',
          ),
          _HelpTile(
            icon: Icons.account_circle_outlined,
            iconColor: Colors.white54,
            title: 'Como gerencio minha conta?',
            body: 'No menu lateral, toque em "Minha Conta":\n\n'
                '• Sair da conta — faz logout do app. Seus dados continuam '
                'salvos na nuvem.\n'
                '• Excluir conta — apaga permanentemente sua conta e todos os '
                'seus dados. Essa ação não pode ser desfeita.\n\n'
                'Seus direitos (LGPD): você tem direito a acessar, corrigir e '
                'excluir seus dados a qualquer momento.\n\n'
                'Dúvidas? Entre em contato: contato@multiversodigital.com.br',
          ),
          SizedBox(height: 16),
          _SectionHeader('PLANO PRO'),
          SizedBox(height: 8),
          _HelpTile(
            icon: Icons.workspace_premium_rounded,
            iconColor: Colors.amber,
            title: 'O que muda no plano Pro?',
            body: 'O plano gratuito oferece um número limitado de análises por '
                'mês. Com o AntiGolpeia Pro você tem:\n\n'
                '• Análises ilimitadas — analise quantas mensagens quiser, '
                'sem limite mensal.\n'
                '• Monitor automático sem restrição — proteção 24h de '
                'WhatsApp, SMS e Gmail.\n'
                '• Prioridade na análise — resultados mais rápidos.\n\n'
                'Para assinar, vá no menu lateral e toque em '
                '"AntiGolpeia Pro". Você pode cancelar a qualquer momento '
                'pela própria loja (Google Play ou App Store).\n\n'
                'Para gerenciar ou cancelar sua assinatura, toque em '
                '"Gerenciar Assinatura" no menu lateral.',
          ),
          _WhyPaidCard(),
          SizedBox(height: 16),
          _SectionHeader('PERGUNTAS FREQUENTES'),
          SizedBox(height: 8),
          _HelpTile(
            icon: Icons.quiz_outlined,
            iconColor: Colors.lightBlueAccent,
            title: 'O app lê minhas conversas inteiras?',
            body: 'Não. O monitor automático só lê o texto que aparece na '
                'notificação — aquele trecho que aparece na barra de status '
                'do celular. Ele não acessa suas conversas completas, '
                'fotos, áudios ou arquivos.',
          ),
          _HelpTile(
            icon: Icons.quiz_outlined,
            iconColor: Colors.lightBlueAccent,
            title: 'Meus dados são compartilhados com terceiros?',
            body: 'Não. Seus dados são protegidos pela LGPD (Lei nº '
                '13.709/2018) e nunca são vendidos ou compartilhados sem '
                'sua autorização.\n\n'
                'O conteúdo das mensagens é anonimizado (dados pessoais como '
                'CPF e telefone são removidos) antes de qualquer '
                'processamento externo.',
          ),
          _HelpTile(
            icon: Icons.quiz_outlined,
            iconColor: Colors.lightBlueAccent,
            title: 'A análise é 100% precisa?',
            body: 'Nenhuma tecnologia é perfeita. A inteligência artificial '
                'acerta na grande maioria dos casos, mas pode errar.\n\n'
                'Sempre use seu bom senso junto com a análise. Na dúvida, '
                'não faça o Pix, não clique no link e confirme a identidade '
                'da pessoa por ligação ou videochamada.',
          ),
          _HelpTile(
            icon: Icons.quiz_outlined,
            iconColor: Colors.lightBlueAccent,
            title: 'O app funciona sem internet?',
            body: 'Não. A análise depende de inteligência artificial que roda '
                'em servidores na nuvem. Sem conexão com a internet, não é '
                'possível analisar mensagens.\n\n'
                'O histórico de análises anteriores pode ser consultado '
                'normalmente mesmo sem internet.',
          ),
          _HelpTile(
            icon: Icons.quiz_outlined,
            iconColor: Colors.lightBlueAccent,
            title: 'Como cancelo o plano Pro?',
            body: 'Vá no menu lateral e toque em "Gerenciar Assinatura". '
                'O cancelamento é feito diretamente pela Google Play ou '
                'App Store — igual a qualquer outro aplicativo.\n\n'
                'Após cancelar, você continua com acesso Pro até o fim do '
                'período já pago.',
          ),
          SizedBox(height: 24),
          _ContactCard(),
        ],
      ),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AntiGolpeConstants.colorSafe.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AntiGolpeConstants.colorSafe.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined,
              color: AntiGolpeConstants.colorSafe, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aqui você encontra tudo sobre como usar o AntiGolpeia e '
              'entender cada função do app.',
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _HelpTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white60,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyPaidCard extends StatelessWidget {
  const _WhyPaidCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withValues(alpha: 0.12),
            Colors.amber.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_outline, color: Colors.pinkAccent, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Por que o AntiGolpeia não é 100% gratuito?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Gostaríamos que o app fosse totalmente gratuito, mas queremos '
            'ser transparentes com você sobre os custos reais.',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 14),
          const _CostItem(
            icon: Icons.psychology_outlined,
            color: Colors.deepPurpleAccent,
            title: 'Inteligência Artificial',
            desc: 'Cada mensagem analisada é processada por uma IA avançada '
                'que cobra por uso. Não é um custo inventado — cada análise '
                'custa dinheiro real para nós.',
          ),
          const SizedBox(height: 10),
          const _CostItem(
            icon: Icons.cloud_outlined,
            color: Colors.blueAccent,
            title: 'Servidores na nuvem',
            desc: 'Seu histórico, backup e alertas ficam em servidores seguros '
                'que funcionam 24h por dia, 7 dias por semana. Manter isso '
                'tem um custo mensal fixo.',
          ),
          const SizedBox(height: 10),
          const _CostItem(
            icon: Icons.phone_outlined,
            color: Colors.orangeAccent,
            title: 'Verificação de números',
            desc: 'Cada consulta de SIM Swap tem custo por uso junto à '
                'operadora de dados de telefonia.',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'O plano gratuito já protege você com várias análises por mês. '
              'O Pro existe para quem quer proteção completa e ilimitada.\n\n'
              'Nosso compromisso: cobrar o mínimo necessário para manter o '
              'app vivo, seguro e atualizado. Se um único golpe for evitado, '
              'o valor já se pagou.\n\n'
              'Obrigado por confiar no AntiGolpeia. ❤',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _CostItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    const email = 'contato@multiversodigital.com.br';
    return GestureDetector(
      onTap: () {
        Clipboard.setData(const ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail copiado!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.white38, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ainda tem dúvidas? Fale com a gente.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70),
                  ),
                  SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
