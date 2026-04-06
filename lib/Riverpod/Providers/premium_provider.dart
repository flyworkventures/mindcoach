import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class PremiumProvider  extends StateNotifier<bool>{
  Ref ref;
  PremiumProvider(this.ref):super(false);

  void changePremiumStatus(BuildContext context){
    if (state) {
      state = false;
    
    }else{
      state = true;
    }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Premium Durumu ${state ? "Aktif" : "Deaktif"}")));
  }
  
}