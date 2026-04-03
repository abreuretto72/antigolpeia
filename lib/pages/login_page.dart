import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    
    final rawEmail = _emailController.text;
    final cleanEmail = rawEmail.trim();
    
    debugPrint('[AUTH LOG] =======================================');
    debugPrint('[AUTH LOG] Attempting Login');
    debugPrint('[AUTH LOG] Raw email length: \${rawEmail.length}, content: "\$rawEmail"');
    debugPrint('[AUTH LOG] Clean email length: \${cleanEmail.length}, content: "\$cleanEmail"');
    
    try {
      debugPrint('[AUTH LOG] Calling signInWithOtp...');
      await Supabase.instance.client.auth.signInWithOtp(
        email: cleanEmail,
        emailRedirectTo: 'io.supabase.antigolpeia://login-callback/',
      );
      debugPrint('[AUTH LOG] Call success, Otp sent.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link de login enviado para o seu e-mail!')),
        );
      }
    } on AuthException catch (e) {
      debugPrint('[AUTH LOG] Supabase AuthException: \${e.message}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('[AUTH LOG] Unexpected error: \$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro inesperado.')));
    } finally {
      debugPrint('[AUTH LOG] =======================================');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONFERE ANTES', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Acesse sua conta para analisar suspeitas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Entrar com Magic Link'),
            ),
          ],
        ),
      ),
    );
  }
}
