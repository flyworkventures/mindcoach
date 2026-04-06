import 'dart:developer';

import 'package:flutter/material.dart';

class Logger {
  static void errorLog({required String text, String? className, String? functionName}){
   log("[$className - $functionName]: $text");
  }


    static void info({required String text, String? className, String? functionName}){
   debugPrint("[$className - $functionName]: $text");
  }


}