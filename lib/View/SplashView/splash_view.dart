import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/View/threed.dart';
import 'package:mindcoach/rive_page.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key});

  @override
  ConsumerState<Splash> createState() => _SplashState();
}

class _SplashState extends ConsumerState<Splash> {

  @override
  void initState() {
    super.initState();
//Future.microtask(()=> Navigator.push(context, CupertinoPageRoute(builder: (context)=> RivePage())));
ref.read(AllControllers.splashController.notifier).init();
  }



  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}