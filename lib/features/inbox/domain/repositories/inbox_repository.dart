import '../../../../core/errors/failures.dart';
import '../entities/message.dart';

abstract class InboxRepository {
  Future<Result<List<Message>>> getMessages();
}
