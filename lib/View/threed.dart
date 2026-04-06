import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Three.js Shape Key Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ShapeKeyControllerPage(),
    );
  }
}

class ShapeKeyControllerPage extends StatefulWidget {
  const ShapeKeyControllerPage({super.key});

  @override
  State<ShapeKeyControllerPage> createState() => _ShapeKeyControllerPageState();
}

class _ShapeKeyControllerPageState extends State<ShapeKeyControllerPage> {
  late WebViewController webViewController;
  double key1Value = 0.0;
  bool isWebViewReady = false;
  
  // Model URL'ini buraya girin
  static const String modelURL = 'https://fly-work.com/lingola/privacy-policy/model.glb';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isWebViewReady = true;
            });
            // WebView yüklendikten sonra modeli yükle
            Future.delayed(const Duration(milliseconds: 500), () {
              loadModelFromURL(modelURL);
            });
          },
        ),
      );
    
    // HTML dosyasını yükle
    // Seçenek 1: Local file (tam yol gerekli)
    final htmlPath = 'assets/index.html';
    if (File(htmlPath).existsSync()) {
      webViewController.loadRequest(Uri.file(htmlPath));
    } else {
      // Seçenek 2: Assets'ten yükle (assets klasörüne kopyalayın)
      // webViewController.loadFlutterAsset('assets/index.html');
      
      // Seçenek 3: HTTP server üzerinden (python -m http.server 8000)
      webViewController.loadRequest(Uri.parse('https://fly-work.com/lingola/privacy-policy/'));
    }
  }

  void _updateKey1Value(double value) {
    setState(() {
      key1Value = value;
    });

    // Flutter'dan JavaScript'e değer gönder
    if (isWebViewReady) {
      webViewController.runJavaScript(
        'window.setKey1Value($value);',
      );
    }
  }

  void loadModelFromURL(String url) {
    // Flutter'dan JavaScript'e URL gönder
    if (isWebViewReady) {
      webViewController.runJavaScript(
        'window.loadModelFromURL("$url");',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shape Key Controller'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // WebView
          Expanded(
            child: WebViewWidget(controller: webViewController),
          ),
          
          // Flutter Slider Kontrolü
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Key 1:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      key1Value.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: key1Value,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: key1Value.toStringAsFixed(2),
                  onChanged: _updateKey1Value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
