import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TwilioService {
  // Constantes de mapeamento das chaves do .env
  static const String _sidKey = 'TWILIO_ACCOUNT_SID';
  static const String _tokenKey = 'TWILIO_AUTH_TOKEN';
  static const String _urlKey = 'TWILIO_LOOKUP_URL';

  Future<Map<String, dynamic>> checkSimSwap(String phone) async {
    final String sid = dotenv.get(_sidKey);
    final String token = dotenv.get(_tokenKey);
    final String baseUrl = dotenv.get(_urlKey);

    final url = Uri.parse('$baseUrl/$phone?Fields=sim_swap');
    final auth = 'Basic ${base64Encode(utf8.encode('$sid:$token'))}';

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': auth},
      );

      final data = jsonDecode(response.body);

      // AuthResult como Objeto - Verificação obrigatória result['success']
      final simSwap = data['sim_swap'];
      return {
        'success': response.statusCode == 200,
        'isSwapped': simSwap?['swapped'] ?? false,
        'last_swap': simSwap?['last_sim_swap_date'],
        'error': response.statusCode != 200 ? data['message'] : null,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
