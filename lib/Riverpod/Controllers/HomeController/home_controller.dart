// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';

class HomeController extends StateNotifier<HomeViewModel>{
  Ref ref;
  HomeController(this.ref) : super(HomeViewModel(null,[]));

  void getMotivationText()async{
   HttpService httpService = HttpService(ref: ref);
   var res  = await httpService.get(path:AppConstants.motivationTexts);
   var json = jsonDecode(res.body);
   if (json["data"]["motivation"] != null &&  json["data"]["tavsiye"] != null) {
      MotivationModel motivationModel = MotivationModel(json["data"]["motivation"], json["data"]["tavsiye"], json["data"]["reality"]);
      state = state.copyWith(motivationModel: motivationModel,texts:  [
                          _pageItem(text: motivationModel.motivationText ?? "", color: Colors.black),
                          _pageItem(text: motivationModel.tavsiyeText ?? "", color: Colors.blueGrey),
                          _pageItem(text: motivationModel.gercekText ?? "", color: Colors.indigo),
                        ]);
   }
  
  }


  Widget _pageItem({required String text, required Color color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15, left: 12, right: 12, top: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }



  
}


class HomeViewModel {
  MotivationModel? motivationModel;
  List<Widget> texts;
  HomeViewModel(this.motivationModel,this.texts);

  HomeViewModel copyWith({
    MotivationModel? motivationModel,
    List<Widget>? texts
  }) {
    return HomeViewModel(
      motivationModel ?? this.motivationModel,
      texts ?? this.texts
    );
  }
}


class MotivationModel {
  String? motivationText;
  String? tavsiyeText;
  String? gercekText;
  MotivationModel(this.motivationText,this.tavsiyeText,this.gercekText);
  

  MotivationModel copyWith({
    String? motivationText,
    String? tavsiyeText,
  }) {
    return MotivationModel(
      motivationText ?? this.motivationText,
      tavsiyeText ?? this.tavsiyeText,
      gercekText ?? gercekText
    );
  }
}
