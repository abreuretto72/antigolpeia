import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'api_service.dart';
import '../pages/result_page.dart';

class ShareExtensionHandler {
  static final ShareExtensionHandler _instance = ShareExtensionHandler._internal();
  factory ShareExtensionHandler() => _instance;
  ShareExtensionHandler._internal();

  StreamSubscription? _intentDataStreamSubscription;
  final _apiService = ApiService();

  void init(BuildContext context) {
    // Listen to text sharing while app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (context.mounted && value.isNotEmpty && value.first.path.isNotEmpty) {
        _processFiles(context, value.first.path);
      }
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // Handle text sharing when app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (context.mounted && value.isNotEmpty && value.first.path.isNotEmpty) {
        _processFiles(context, value.first.path);
      }
      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
    });
  }

  void initTextSharing(BuildContext context) {
     init(context);
  }

  void _processFiles(BuildContext context, String content) {
    _analyzeAndNavigate(context, content);
  }

  Future<void> _analyzeAndNavigate(BuildContext context, String content) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Analisando conteúdo compartilhado..."),
          ],
        ),
      ),
    );

    try {
      final result = await _apiService.analyzeContent('text', content);
      if (!context.mounted) return;
      
      Navigator.pop(context); // Close loading
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(result: result)),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro na análise automática: $e")),
        );
      }
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
