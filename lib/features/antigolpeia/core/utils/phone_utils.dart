/// Utilitário de normalização de números de telefone — formato canônico brasileiro.
///
/// Forma canônica: apenas dígitos, sem DDI, com DDD.
/// Exemplos: "+55 (11) 9 9999-0000" → "11999990000"
///           "(11) 9xxxx-xxxx"       → "119xxxxxxxx"
///           "011 9xxxx-xxxx"        → "119xxxxxxxx"
class PhoneUtils {
  PhoneUtils._();

  /// Normaliza [raw] para a forma canônica: dígitos, sem DDI 55, sem zero inicial.
  ///
  /// Garante match cross-platform entre:
  /// - Android (A25): `(11) 9xxxx-xxxx`
  /// - iOS: `+55 11 9xxxx-xxxx`
  static String normalize(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove zero inicial (ex: "011 ...")
    if (digits.startsWith('0')) digits = digits.substring(1);

    // Remove DDI brasileiro: 55 + DDD(2) + número(8 ou 9) = 12 ou 13 dígitos
    if ((digits.length == 12 || digits.length == 13) &&
        digits.startsWith('55')) {
      digits = digits.substring(2);
    }

    return digits;
  }

  /// Retorna `true` se [a] e [b] são o mesmo número após normalização.
  static bool sameNumber(String a, String b) =>
      normalize(a) == normalize(b) && normalize(a).isNotEmpty;
}
