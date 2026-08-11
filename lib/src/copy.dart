import 'package:flutter/widgets.dart';

class SeatCopy {
  SeatCopy(this.language);
  final String language;
  bool get ar => language == 'ar';
  String t(String en, String arText) => ar ? arText : en;
  String get inbox => t('Inbox', 'الطلبات');
  String get today => t('Today', 'اليوم');
  String get settings => t('Settings', 'الإعدادات');
  static SeatCopy of(BuildContext context) =>
      SeatCopy(Localizations.localeOf(context).languageCode);
}
