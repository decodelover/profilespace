import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/inbox_repository.dart';

class InboxRepositoryImpl implements InboxRepository {
  final Dio dio;

  const InboxRepositoryImpl({required this.dio});

  @override
  Future<Result<List<Message>>> getMessages() async {
    try {
      final response = await dio.get('/messages');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        
        final messages = data.map((item) {
          final map = item as Map<String, dynamic>;
          return Message(
            id: map['id'].toString(),
            senderName: map['sender_name'] as String,
            senderEmail: map['sender_email'] as String,
            company: map['company'] as String?,
            message: map['message'] as String,
            tag: map['tag'] as String? ?? 'recruiter',
            createdAt: DateTime.parse(map['created_at'] as String),
          );
        }).toList();

        return Result.success(messages);
      }
      return Result.failure(ServerFailure(message: 'Failed to fetch messages.'));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            'Failed to load inbox.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
