import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as v1;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'api_service.dart';

class GmailService {
  static final GmailService _instance = GmailService._internal();
  factory GmailService() => _instance;
  GmailService._internal();

  final _apiService = ApiService();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      // authenticate() is the new sign-in method in 7.x
      final account = await GoogleSignIn.instance.authenticate();
      return account;
    } catch (e) {
      debugPrint('Gmail sign in error: $e');
      return null;
    }
  }

  Future<void> scanEmails() async {
    await _ensureInitialized();
    // attemptLightweightAuthentication() replaces signInSilently()
    final account = await GoogleSignIn.instance.attemptLightweightAuthentication() 
        ?? await GoogleSignIn.instance.authenticate();
        
    // account is non-null: authenticate() throws on failure

    final scopes = [v1.GmailApi.gmailReadonlyScope];

    // In extension 3.0.0+, use authorizationClient.authorizeScopes
    final authorization = await account.authorizationClient.authorizeScopes(scopes);
    
    // Then get the auth client
    final auth.AuthClient client = authorization.authClient(scopes: scopes);

    final gmailApi = v1.GmailApi(client);
    
    // Fetch last 10 messages
    final listResponse = await gmailApi.users.messages.list('me', maxResults: 10);
    final messages = listResponse.messages ?? [];

    for (var msgRef in messages) {
      final msg = await gmailApi.users.messages.get('me', msgRef.id!);
      final content = _extractBody(msg);
      
      if (content.length > 20) {
        final result = await _apiService.analyzeContent('email', content);
        if (result['risco'] > 70) {
          debugPrint('ALERTA GMAIL: ${result['tipo_golpe']} em e-mail id ${msg.id}');
        }
      }
    }
  }

  String _extractBody(v1.Message msg) {
    final payload = msg.payload;
    if (payload == null) return "";
    
    if (payload.parts != null) {
      for (var part in payload.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return _decodeBase64(part.body!.data!);
        }
      }
    }
    
    if (payload.body?.data != null) {
       return _decodeBase64(payload.body!.data!);
    }

    return "";
  }

  String _decodeBase64(String data) {
    return utf8.decode(base64Url.decode(data));
  }
}
