import '../../../core/constants/enums.dart';

String formatNotificationTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String formatRequestStatus(RequestStatus status) {
  return status
      .toString()
      .split('.')
      .last
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
      .trim();
}
