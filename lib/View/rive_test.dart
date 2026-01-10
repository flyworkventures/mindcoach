import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveView extends StatefulWidget {
  const RiveView({super.key});

  @override
  State<RiveView> createState() => _RiveViewState();
}

class _RiveViewState extends State<RiveView> {

 StateMachineController? _controller;
  SMIBool? isTalking;
SMINumber? agizKodu;

void _onRiveInit(Artboard artboard) {
  final controller = StateMachineController.fromArtboard(
    artboard,
    'State Machine 2',
  );

  if (controller == null) {
    debugPrint('STATE MACHINE BULUNAMADI');
    return;
  }

  artboard.addController(controller);

  agizKodu = controller.findInput<double>('agiz_kodu') as SMINumber?;

  if (agizKodu == null) {
    debugPrint('agiz_kodu BULUNAMADI');
  }
  Timer.periodic(Duration(seconds: 2), (a){
      setState(() {
   agizKodu?.value++;
  });
  });
}


@override
  void initState() {

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
        SizedBox(
          height: 300,
          child: RiveAnimation.asset(
            'assets/character_3d.riv',
            stateMachines: const ['State Machine 2'],
            onInit: _onRiveInit,
            fit: BoxFit.contain,
          ),
        ),
ElevatedButton(
  onPressed: () => agizKodu?.value = 1,
  child: Text('A'),
),
ElevatedButton(
  onPressed: () => agizKodu?.value = 2,
  child: Text('O'),
),
ElevatedButton(
  onPressed: () => agizKodu?.value = 0,
  child: Text('Kapalı'),
),

        ],
      ),
    );
  }


  void startTalking() {
  isTalking?.value = true;

  Timer.periodic(const Duration(milliseconds: 120), (timer) {
    if (isTalking?.value == false) {
      timer.cancel();
    }
  });
}
}