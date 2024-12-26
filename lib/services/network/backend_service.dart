import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

BackendService backend = Get.isRegistered<BackendService>() ? Get.find<BackendService>() : Get.put(RustPushBackend());
enum ParticipantOp { Add, Remove }

abstract class BackendService {
  Future<Chat> createChat(List<String> addresses, AttributedBody? message, String service,
      {CancelToken? cancelToken, String? existingGuid});
  Future<Message> sendMessage(Chat c, Message m, {CancelToken? cancelToken});
  Future<bool> renameChat(Chat chat, String newName);
  Future<bool> chatParticipant(ParticipantOp method, Chat chat, String newName);
  Future<void> moveToRecycleBin(Chat c, Message? message);
  Future<void> restoreChat(Chat c);
  Future<void> permanentlyDeleteChat(Chat c);
  Future<bool> leaveChat(Chat chat);
  Future<Message> sendTapback(
      Chat chat, Message selected, String reaction, int? repPart);
  Future<Message> updateMessage(
      Chat chat, Message old, PayloadData newData);
  Future<bool> markRead(Chat chat, bool notifyOthers);
  Future<bool> markUnread(Chat chat);
  HttpService? getRemoteService();
  bool canLeaveChat();
  bool canEditUnsend();
  bool canSendSubject();
  Future<Message?> unsend(Message msg, MessagePart part);
  Future<Message?> edit(Message msgGuid, AttributedBody text, int part);
  Future<PlatformFile> downloadAttachment(Attachment attachment,
      {void Function(int, int)? onReceiveProgress, bool original = false, CancelToken? cancelToken});
  // returns the new message that was sent
  Future<Message> sendAttachment(Chat c, Message m, bool isAudioMessage, Attachment attachment,
      {void Function(int, int)? onSendProgress, CancelToken? cancelToken});
  bool canCancelUploads();
  Future<bool> canUploadGroupPhotos();
  Future<bool> setChatIcon(Chat chat, String path,
      {void Function(int, int)? onSendProgress, CancelToken? cancelToken});
  Future<bool> deleteChatIcon(Chat chat, {CancelToken? cancelToken});
  bool supportsFocusStates();
  Future<bool> downloadLivePhoto(Attachment att, String target,
      {void Function(int, int)? onReceiveProgress, CancelToken? cancelToken});
  bool canSchedule();
  bool supportsFindMy();
  bool canCreateGroupChats();
  bool supportsSmsForwarding();
  void startedTyping(Chat c);
  void stoppedTyping(Chat c);
  void updateTypingStatus(Chat c);
  Future<bool> handleiMessageState(String address);
  Future<Map<String, dynamic>> getAccountInfo();
  Future<void> setDefaultHandle(String handle);
  Future<Map<String, dynamic>> getAccountContact();
  void init();
  bool canDelete(); // use hard delete
}
