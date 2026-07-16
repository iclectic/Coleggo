enum WorkplaceVerificationStatus { codeSent, verified, rejected }

class WorkplaceVerificationSession {
  const WorkplaceVerificationSession({
    required this.id,
    required this.workplaceId,
    required this.worksiteId,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String workplaceId;
  final String worksiteId;
  final String email;
  final WorkplaceVerificationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class WorkplaceVerificationResult {
  const WorkplaceVerificationResult({
    required this.verified,
    required this.session,
    this.message,
  });

  final bool verified;
  final WorkplaceVerificationSession session;
  final String? message;
}
