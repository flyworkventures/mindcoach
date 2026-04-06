import 'package:flutter/material.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

class  AppConstants {
  static const String defaultPpUrl = "https://mindcoach.b-cdn.net/1024x1024.jpg"; 
  static const String baseURL  = "https://mind.fly-work.com"; //https://mind.fly-work.com
  static const String onesignalId = "b3ba2ab4-03a9-45dc-a303-f0a92d7d1410";
  static const String googleAuth = "/auth/google";
  static const String facebookAuth = "/auth/facebook";
  static const String appleAuth = "/auth/apple";
  static const String guestAuth = "/auth/guest";
  static const String verifyTokenURL = "/auth/verify";
  static const String motivationTexts = "/motivationtexts";
  static const String completeProfileURL = "/auth/profile";
  static const String getUserProfileURL = "/auth/m be";
  static const String logoutURL = "/auth/logout";
  static const String deleteAccountURL = "/auth/account";
  static const String consultantsURL = "/consultants";
  static const String consultantssendMessageURL = "/chats/send";
  static const String sendPremiumMessageURL = "/chats/send-premium";
  static const String sendGeneralAssistantMessageURL = "/chats/general-assistant-message";
  static const String getUserChatsURL = "/chats";
  static String getChatByIdURL(int chatId) => "/chats/$chatId";
  static  String getMessagesFromConsultantIdURL(String id) => "/chats/consultant/$id/messages";
  static String deleteChatURL(int consultantId) => "/chats/consultant/$consultantId";
  
  // Mood endpoints
  static String getUserMoodsURL(int userId) => "/moods/user/$userId";
  static const String createOrUpdateMoodURL = "/moods";
  
  // Appointment endpoints
  static String getAllAppointmentsURL(int userId) => "/appointments/user/$userId";
  static String getUpcomingAppointmentURL(int userId) => "/appointments/user/$userId/upcoming";
  static String cancelAppointmentURL(int appointmentId) => "/appointments/$appointmentId";
  static String reactivateAppointmentURL(int appointmentId) => "/appointments/$appointmentId/reactivate";
  
  // Video Call endpoint
  static const String videoCallURL = "/video-call";
  
  // Notification endpoints
  static const String getNotificationsURL = "/notifications";
  static String getNotificationByIdURL(int id) => "/notifications/$id";
  static String deleteNotificationURL(int id) => "/notifications/$id";
  static const String deleteAllNotificationsURL = "/notifications";





 static Iterable<LocalizationsDelegate<dynamic>>  localizationsDelegates = [
  AppLocalizations.delegate,


];



  static List<Locale> supportedLocales = const[
  Locale('en','US'),
  Locale('tr','TR'),
];



}