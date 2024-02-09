import 'package:intl/intl.dart';

import '../../../services/logger_service.dart';

class TimeSheetUtils {
  static int getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static DateTime parseDate(String date) {
    final parsedDate = DateFormat("dd-MMM-yy").parse(date, true);
    logger.i('parsedDate: $parsedDate');
    return parsedDate;
  }

  static String formatDate(DateTime date) {
    return DateFormat("dd-MMM-yy").format(date);
  }

  static String convertFormatDate(String date) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final newFormat = DateFormat('dd-MMM-yy');

    DateTime dateTime = dateFormat.parse(date);
    return newFormat.format(dateTime);
  }
}
