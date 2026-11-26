import 'package:dio/dio.dart';

import '../models/commute_circle.dart';
import '../models/message_thread.dart';
import '../services/backend_api_client.dart';
import 'repository_interfaces.dart';

class BackendMessagingRepository implements MessagingRepository {
  BackendMessagingRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<MessageThread>> getOrCreateCircleThread({
    required List<MessageThread> threads,
    required CommuteCircle circle,
    required String requesterProfileId,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/circles/${circle.id}/messages',
      );
      final data = response.data!;
      final messages = (data['messages'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_mapMessage)
          .toList();
      return RepositoryResult.data(
        MessageThread(
          id: data['threadId'] as String? ?? 'thread-${circle.id}',
          type: MessageThreadType.commuteCircle,
          contextId: circle.id,
          participantProfileIds: circle.members
              .map((member) => member.profileId)
              .toList(),
          messages: messages,
          createdAt: DateTime.now(),
        ),
      );
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<MessageThread>> sendMessage({
    required MessageThread thread,
    required String senderProfileId,
    required String body,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/circles/${thread.contextId}/messages',
        data: {'body': body},
        idempotencyKey:
            'msg-${thread.contextId}-${DateTime.now().millisecondsSinceEpoch}',
      );
      final message = _mapMessage(
        response.data!['message'] as Map<String, dynamic>,
      );
      return RepositoryResult.data(
        thread.copyWith(messages: [...thread.messages, message]),
      );
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<MessageModerationReport>> reportMessage({
    required MessageThread thread,
    required CommuteMessage message,
    required String reporterProfileId,
    required String reason,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/messages/${message.id}/report',
        data: {'reason': reason},
        idempotencyKey: 'report-${message.id}-$reporterProfileId',
      );
      final report = response.data!['report'] as Map<String, dynamic>;
      return RepositoryResult.data(
        MessageModerationReport(
          id: report['id'] as String,
          threadId: thread.id,
          messageId: message.id,
          reporterProfileId: reporterProfileId,
          reason: report['reason'] as String? ?? reason,
          createdAt: DateTime.tryParse(report['createdAt'] as String? ?? '') ??
              DateTime.now(),
        ),
      );
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  CommuteMessage _mapMessage(Map<String, dynamic> json) => CommuteMessage(
        id: json['id'] as String,
        threadId: json['threadId'] as String,
        senderProfileId: json['senderProfileId'] as String,
        body: json['body'] as String,
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
            DateTime.now(),
        deliveryState: MessageDeliveryState.values.byName(
          json['deliveryState'] as String? ?? 'stored',
        ),
      );
}
