import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';

class LegalDocScreen extends StatelessWidget {
  final String assetPath;
  final String title;

  const LegalDocScreen({super.key, required this.assetPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title),),
      body: FutureBuilder(
          future: rootBundle.loadString(assetPath),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Markdown(data: snapshot.data!);
            }
            return const Center(child: CircularProgressIndicator(),);
          }

          ),

    );
  }
}
