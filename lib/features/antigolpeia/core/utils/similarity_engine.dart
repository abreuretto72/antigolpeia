/// Motor de similaridade textual puro em Dart.
/// Sem dependências externas — adequado para execução em Isolates.
class SimilarityEngine {
  SimilarityEngine._();

  /// Retorna valor de 0.0 (totalmente diferente) a 1.0 (idêntico).
  /// Usa Levenshtein com otimização de memória O(2n) — duas linhas.
  static double compare(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Limitar tamanho para evitar quadrático em textos grandes
    final s1 = a.length > 500 ? a.substring(0, 500) : a;
    final s2 = b.length > 500 ? b.substring(0, 500) : b;

    final prev = List<int>.generate(s2.length + 1, (j) => j);
    final curr = List<int>.filled(s2.length + 1, 0);

    for (var i = 1; i <= s1.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = _min3(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
      }
      prev.setAll(0, curr);
    }

    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - curr[s2.length] / maxLen;
  }

  /// Normaliza o texto antes de comparar: minúsculas + trim + colapsa espaços.
  static String normalize(String text) =>
      text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Compara versões normalizadas dos textos.
  static double compareNormalized(String a, String b) =>
      compare(normalize(a), normalize(b));

  static int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}
