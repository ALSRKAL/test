import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.photographerId,
    required super.photographerName,
    super.photographerAvatar,
    required super.clientId,
    required super.clientName,
    super.clientAvatar,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount,
    super.isOnline,
    required super.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Determine other participant
    final otherParticipant = json['otherParticipant'] ?? {};
    final participants = json['participants'] as List<dynamic>? ?? [];
    
    // Parse unreadCount - can be int or Map
    int unreadCount = 0;
    final unreadCountData = json['unreadCount'];
    if (unreadCountData is int) {
      unreadCount = unreadCountData;
    } else if (unreadCountData is Map) {
      unreadCount = 0;
    }
    
    // Determine photographer and client IDs
    String photographerId = '';
    String photographerName = '';
    String? photographerAvatar;
    String clientId = '';
    String clientName = '';
    String? clientAvatar;
    
    // Check participantDetails first
    if (json['participantDetails'] != null) {
      photographerId = json['participantDetails']['photographer'] ?? '';
      clientId = json['participantDetails']['client'] ?? '';
    }
    
    // Use otherParticipant info
    if (otherParticipant.isNotEmpty) {
      final otherRole = otherParticipant['role'] ?? '';
      if (otherRole == 'photographer') {
        photographerId = otherParticipant['_id'] ?? '';
        photographerName = otherParticipant['name'] ?? '';
        photographerAvatar = otherParticipant['avatar'];
      } else {
        clientId = otherParticipant['_id'] ?? '';
        clientName = otherParticipant['name'] ?? '';
        clientAvatar = otherParticipant['avatar'];
      }
    }
    
    // Fallback: use participants list
    if (participants.isNotEmpty) {
      for (var participant in participants) {
        final role = participant['role'] ?? '';
        final id = participant['_id'] ?? '';
        final name = participant['name'] ?? '';
        final avatar = participant['avatar'];
        
        if (role == 'photographer') {
          if (photographerId.isEmpty) photographerId = id;
          if (photographerName.isEmpty) photographerName = name;
          if (photographerAvatar == null) photographerAvatar = avatar;
        } else {
          if (clientId.isEmpty) clientId = id;
          if (clientName.isEmpty) clientName = name;
          if (clientAvatar == null) clientAvatar = avatar;
        }
      }
    }
    
    // If still missing names, use otherParticipant as fallback
    if (otherParticipant.isNotEmpty) {
      final otherId = otherParticipant['_id'] ?? '';
      final otherName = otherParticipant['name'] ?? '';
      final otherAvatar = otherParticipant['avatar'];
      
      // If photographer info is missing and other is photographer
      if (photographerName.isEmpty && photographerId == otherId) {
        photographerName = otherName;
        photographerAvatar = otherAvatar;
      }
      // If client info is missing and other is client
      if (clientName.isEmpty && clientId == otherId) {
        clientName = otherName;
        clientAvatar = otherAvatar;
      }
    }
    
    return ConversationModel(
      id: json['_id'] ?? '',
      photographerId: photographerId,
      photographerName: photographerName.isEmpty ? 'مصورة' : photographerName,
      photographerAvatar: photographerAvatar,
      clientId: clientId,
      clientName: clientName.isEmpty ? 'عميل' : clientName,
      clientAvatar: clientAvatar,
      lastMessage: json['lastMessageText'] ?? json['lastMessage']?['content'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
      unreadCount: unreadCount,
      isOnline: false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'photographerId': photographerId,
      'photographerName': photographerName,
      'photographerAvatar': photographerAvatar,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
