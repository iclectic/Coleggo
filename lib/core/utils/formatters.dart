import 'package:intl/intl.dart';

const weekdayLabels = <int, String>{
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
};

String formatMinutes(int minutes) {
  final date = DateTime(2020, 1, 1, minutes ~/ 60, minutes % 60);
  return DateFormat('HH:mm').format(date);
}

String formatDays(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayLabels[day]).join(', ');
}

String pluralise(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : plural ?? '${singular}s'}';
