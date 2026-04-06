import 'package:permission_handler/permission_handler.dart';

/// Resultado tipado da solicitação de permissão de contatos.
class ContactAuthResult {
  final bool success;
  final bool isPermanentlyDenied;

  const ContactAuthResult({
    required this.success,
    required this.isPermanentlyDenied,
  });

  static const ContactAuthResult granted =
      ContactAuthResult(success: true, isPermanentlyDenied: false);

  static const ContactAuthResult denied =
      ContactAuthResult(success: false, isPermanentlyDenied: false);

  static const ContactAuthResult permanentlyDenied =
      ContactAuthResult(success: false, isPermanentlyDenied: true);
}

/// Gerencia a permissão de leitura de contatos em Android e iOS.
///
/// No iOS, `isPermanentlyDenied` é retornado após a primeira negação — a Apple
/// não permite uma segunda solicitação em tempo de execução. O chamador deve
/// redirecionar o usuário para Ajustes quando isso ocorrer.
class ContactsPermissionService {
  Future<ContactAuthResult> checkAndRequest() async {
    PermissionStatus status = await Permission.contacts.status;

    if (status.isGranted) return ContactAuthResult.granted;

    if (status.isPermanentlyDenied) return ContactAuthResult.permanentlyDenied;

    status = await Permission.contacts.request();

    if (status.isGranted) return ContactAuthResult.granted;
    if (status.isPermanentlyDenied) return ContactAuthResult.permanentlyDenied;

    return ContactAuthResult.denied;
  }
}
