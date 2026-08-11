import 'package:intl/intl.dart';

String seatDateTime(DateTime value, String language) {
  final local = value.toLocal();
  final formatted = DateFormat(
    language == 'ar' ? 'EEE d MMM · h:mm a' : 'EEE, d MMM · h:mm a',
    language,
  ).format(local);
  return formatted.replaceAllMapped(
    RegExp(r'[٠-٩]'),
    (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m.group(0)!).toString(),
  );
}

String requestAge(DateTime createdAt, DateTime now, String language) {
  final minutes = now.difference(createdAt).inMinutes.clamp(0, 999);
  return language == 'ar' ? 'منذ $minutes دقيقة' : '${minutes}m ago';
}
