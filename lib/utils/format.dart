// Utility helpers for formatting sizes, durations and text.

String formatBytes(num bytes) {
  if (bytes <= 0) return '0 B';
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  final value = bytes.toDouble();
  if (value >= gb) return '${(value / gb).toStringAsFixed(2)} GB';
  if (value >= mb) return '${(value / mb).toStringAsFixed(2)} MB';
  if (value >= kb) return '${(value / kb).toStringAsFixed(2)} KB';
  return '${bytes.toStringAsFixed(0)} B';
}

/// Formats a number of minutes as "Xh Ym" or "Y min".
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0 min';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Truncates a string to [max] characters, appending an ellipsis.
String truncate(String text, int max) {
  if (text.length <= max) return text;
  return '${text.substring(0, max - 1)}…';
}

/// Capitalizes the first letter of a string.
String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
