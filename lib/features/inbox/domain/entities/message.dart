import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String senderName;
  final String senderEmail;
  final String? company;
  final String message;
  final String tag;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    this.company,
    required this.message,
    required this.tag,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        senderName,
        senderEmail,
        company,
        message,
        tag,
        createdAt,
      ];
}
