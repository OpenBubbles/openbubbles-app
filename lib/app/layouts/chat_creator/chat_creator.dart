import 'dart:async';
import 'dart:math';

import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/app/layouts/chat_creator/widgets/chat_creator_tile.dart';
import 'package:bluebubbles/app/layouts/conversation_view/pages/conversation_view.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/conversation_text_field.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/app/wrappers/titlebar_wrapper.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/conversation_view/pages/messages_view.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/string_utils.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:get/get.dart' hide Response;
import 'package:slugify/slugify.dart';
import 'package:tuple/tuple.dart';

class SelectedContact {
  final String displayName;
  final String address;
  late final RxnBool iMessage;

  SelectedContact({required this.displayName, required this.address, bool? isIMessage}) {
    iMessage = RxnBool(isIMessage);
  }
}

class ChatCreator extends StatefulWidget {
  const ChatCreator({
    super.key,
    this.initialText = "",
    this.initialAttachments = const [],
    this.initialSelected = const [],
  });

  final String? initialText;
  final List<PlatformFile> initialAttachments;
  final List<SelectedContact> initialSelected;

  @override
  ChatCreatorState createState() => ChatCreatorState();
}

class ChatCreatorState extends OptimizedState<ChatCreator> {
  final TextEditingController addressController = TextEditingController();
  final messageNode = FocusNode();
  late final MentionTextEditingController textController = MentionTextEditingController(text: widget.initialText, focusNode: messageNode);
  final FocusNode addressNode = FocusNode();
  final ScrollController addressScrollController = ScrollController();

  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  List<Chat> existingChats = [];
  List<Chat> filteredChats = [];
  late final RxList<SelectedContact> selectedContacts = List<SelectedContact>.from(widget.initialSelected).obs;
  final Rxn<ConversationViewController> fakeController = Rxn(null);
  bool iMessage = true;
  bool sms = false;
  String? oldText;
  ConversationViewController? oldController;
  Timer? _debounce;
  Completer<void>? createCompleter;
  int selectedSuggestionIndex = -1;
  int previousSuggestionIndex = -1;
  final Map<int, GlobalKey> suggestionKeys = {};

  bool canCreateGroupChats = backend.canCreateGroupChats();

  @override
  void initState() {
    super.initState();

    // submit when they go to write a message
    messageNode.addListener(() {
      if (messageNode.hasFocus && addressController.text.trim() != "") {
        addressOnSubmitted();
      }
    });

    addressController.addListener(() {
      _debounce?.cancel();
      Logger.debug("right app");
      _debounce = Timer(const Duration(milliseconds: 250), () async {
        final tuple = await SchedulerBinding.instance.scheduleTask(() async {
          // If you type and then delete everything, show selected chat view
          if (addressController.text.isEmpty && selectedContacts.isNotEmpty) {
            await findExistingChat();
            return Tuple2(contacts, existingChats);
          }

          if (addressController.text != oldText) {
            oldText = addressController.text;
            // if user has typed stuff, remove the message view and show filtered results
            if (addressController.text.isNotEmpty && fakeController.value != null) {
              await cm.setAllInactive();
              oldController = fakeController.value;
              fakeController.value = null;
            }
          }
          final query = addressController.text.toLowerCase();
          Logger.debug("here");
          final _contacts = contacts
              .where((e) =>
                  e.displayName.toLowerCase().contains(query) ||
                  e.phones.firstWhereOrNull((e) => cleansePhoneNumber(e.toLowerCase()).contains(query)) != null ||
                  e.emails.firstWhereOrNull((e) => e.toLowerCase().contains(query)) != null)
              .toList();
          Logger.debug("contacts  $_contacts");
          final ids = _contacts.map((e) => e.id);
          final _chats = existingChats.where((e) =>
              ((iMessage && e.isIMessage) || (sms && !e.isIMessage)) &&
              ((e.title?.toLowerCase().contains(query) ?? false) ||
                  e.participants.firstWhereOrNull((e) =>
                          ids.contains(e.contact?.id) ||
                          e.address.contains(query) ||
                          e.displayName.toLowerCase().contains(query)) !=
                      null));
          return Tuple2(_contacts, _chats);
        }, Priority.animation);
        _debounce = null;
        setState(() {
          filteredContacts = List<Contact>.from(tuple.item1);
          filteredChats = List<Chat>.from(tuple.item2);
          if (addressController.text.isNotEmpty) {
            filteredChats.sort((a, b) => a.participants.length.compareTo(b.participants.length));
          }
          final totalSuggestions = _totalSuggestions;
          if (addressController.text.isEmpty || totalSuggestions == 0) {
            selectedSuggestionIndex = -1;
          } else if (selectedSuggestionIndex < 0 || selectedSuggestionIndex >= totalSuggestions) {
            selectedSuggestionIndex = 0;
          }
        });
      });
    });

    updateObx(() {
      if (widget.initialAttachments.isEmpty && !kIsWeb) {
        final query = (Database.contacts.query()..order(Contact_.displayName)).build();
        contacts = query.find().toSet().toList();
        filteredContacts = List<Contact>.from(contacts);
      }
      if (chats.loadedAllChats.isCompleted) {
        existingChats = chats.chats;
        filteredChats = List<Chat>.from(existingChats.where((e) => e.isIMessage));
      } else {
        chats.loadedAllChats.future.then((_) {
          existingChats = chats.chats;
          setState(() {
            filteredChats = List<Chat>.from(existingChats.where((e) => e.isIMessage));
          });
        });
      }
      setState(() {});
      if (widget.initialSelected.isNotEmpty) {
        findExistingChat();
      }
    });

    if (widget.initialSelected.isNotEmpty) messageNode.requestFocus();
  }

  Future<void> addSelected(SelectedContact c) async {
    selectedContacts.add(c);
    try {
      c.iMessage.value = await backend.handleiMessageState(c.address);
      if (!c.iMessage.value! && !ss.settings.nonIMessageWarning.value) {
        await showDialog(
          context: Get.context!,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "This recipient is GREEN because they do not have iMessage or you are being rate-limited.",
                style: context.theme.textTheme.titleLarge,
              ),
              content: Text(
                "${ss.settings.smsForwardingTargets.isEmpty ? 'You can start a text here, and sending it will open your default messaging app. ' : ''}Rate limits can start at 0 users for brand new accounts. The only way to resolve a rate limit is patience, trying to reconfigure or re-install to 'fix' the rate limit will result in being temporarily blocked from iMessage.",
                style: context.theme.textTheme.bodyLarge,
              ),
              backgroundColor: context.theme.colorScheme.properSurface,
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "Ok",
                    style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    ss.settings.nonIMessageWarning.value = true;
                    await ss.settings.saveOne('nonIMessageWarning');
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (_) {}
    addressController.text = "";
    findExistingChat();
  }

  void addSelectedList(Iterable<SelectedContact> c) {
    selectedContacts.addAll(c);
    addressController.text = "";
    findExistingChat();
  }

  void removeSelected(SelectedContact c) {
    selectedContacts.remove(c);
    findExistingChat();
  }

  GlobalKey _suggestionKey(int index) => suggestionKeys.putIfAbsent(index, () => GlobalKey());

  void _scrollSelectedSuggestionIntoView() {
    if (selectedSuggestionIndex < 0) return;
    final movingUp = previousSuggestionIndex >= 0 && selectedSuggestionIndex < previousSuggestionIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _suggestionKey(selectedSuggestionIndex).currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 150),
        alignment: movingUp ? 0 : 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  int get _totalSuggestions {
    int contactSuggestions = 0;
    for (final contact in filteredContacts) {
      contactSuggestions += getUniqueNumbers(contact.phones).length + getUniqueEmails(contact.emails).length;
    }
    return filteredChats.length + contactSuggestions;
  }

  Future<bool> _selectSuggestionAt(int index) async {
    if (index < 0) return false;
    if (index < filteredChats.length) {
      addSelectedList(filteredChats[index].participants
          .where((e) => selectedContacts.firstWhereOrNull((c) => c.address == e.address) == null)
          .map((e) => SelectedContact(
                displayName: e.displayName,
                address: e.address,
                isIMessage: filteredChats[index].isIMessage,
              )));
      return true;
    }

    int contactIndex = index - filteredChats.length;
    for (final contact in filteredContacts) {
      final phones = getUniqueNumbers(contact.phones);
      if (contactIndex < phones.length) {
        final address = phones[contactIndex];
        if (selectedContacts.firstWhereOrNull((c) => c.address == address) != null) return true;
        await addSelected(SelectedContact(displayName: contact.displayName, address: address));
        return true;
      }
      contactIndex -= phones.length;

      final emails = getUniqueEmails(contact.emails);
      if (contactIndex < emails.length) {
        final address = emails[contactIndex];
        if (selectedContacts.firstWhereOrNull((c) => c.address == address) != null) return true;
        await addSelected(SelectedContact(displayName: contact.displayName, address: address));
        return true;
      }
      contactIndex -= emails.length;
    }

    return false;
  }

  Future<Chat?> findExistingChat({bool checkDeleted = false, bool update = true}) async {
    // no selected items, remove message view
    if (selectedContacts.isEmpty) {
      await cm.setAllInactive();
      fakeController.value = null;
      return null;
    }
    if (selectedContacts.any((element) => element.iMessage.value == false)) {
      setState(() {
        iMessage = false;
        textController.supportsFormatting = false;
        sms = true;
        filteredChats = List<Chat>.from(existingChats.where((e) => !e.isIMessage));
      });
    } else {
      setState(() {
        iMessage = true;
        textController.supportsFormatting = true;
        sms = false;
        filteredChats = List<Chat>.from(existingChats.where((e) => e.isIMessage));
      });
    }
    Chat? existingChat;
    // try and find the chat simply by identifier
    if (selectedContacts.length == 1) {
      final address = selectedContacts.first.address;
      try {
        if (kIsWeb) {
          existingChat = await Chat.findOneWeb(chatIdentifier: slugify(address, delimiter: ''));
        } else {
          final query = Database.chats.query(Chat_.chatIdentifier.equals(slugify(address, delimiter: '')).and(Chat_.isRoutingStub.equals(false).or(Chat_.isRoutingStub.isNull()))).build();
          final result = query.find();
          existingChat = result.firstWhere((element) => element.isIMessage == iMessage);
          query.close();
        }
      } catch (_) {}
    }
    // match each selected contact to a participant in a chat
    if (existingChat == null) {
      for (Chat c in (checkDeleted ? Database.chats.getAll() : filteredChats)) {
        if (c.participants.length != selectedContacts.length) continue;
        if (c.isIMessage != iMessage) continue; // mke sure imessage status is the same
        if (c.isRoutingStub) continue;
        int matches = 0;
        for (SelectedContact contact in selectedContacts) {
          for (Handle participant in c.participants) {
            // If one is an email and the other isn't, skip
            if (contact.address.isEmail && !participant.address.isEmail) continue;
            if (contact.address == participant.address) {
              matches += 1;
              break;
            }
            // match last digits
            final matchLengths = [15, 14, 13, 12, 11, 10, 9, 8, 7];
            final numeric = contact.address.numericOnly();
            if (matchLengths.contains(numeric.length) && cleansePhoneNumber(participant.address).endsWith(numeric)) {
              matches += 1;
              break;
            }
          }
        }
        if (matches == selectedContacts.length) {
          existingChat = c;
          break;
        }
      }
    }
    // if match, show message view, otherwise hide it
    if (update) {
      if (existingChat != null) {
        await cm.setActiveChat(existingChat, clearNotifications: false);
        cm.activeChat!.controller = cvc(existingChat);

        if (widget.initialAttachments.isNotEmpty) {
          cm.activeChat!.controller!.pickedAttachments.value = widget.initialAttachments;
        } else if (fakeController.value != null && fakeController.value!.pickedAttachments.isNotEmpty) {
          cm.activeChat!.controller!.pickedAttachments.value = fakeController.value!.pickedAttachments;
        }

        if (widget.initialText != null && widget.initialText!.isNotEmpty) {
          cm.activeChat!.controller!.textController.text = widget.initialText!;
        } else if (fakeController.value?.textController.text != null && fakeController.value!.textController.text.isNotEmpty) {
          cm.activeChat!.controller!.textController.text = fakeController.value!.textController.text;
        } else if (textController.text.isNotEmpty) {
          cm.activeChat!.controller!.textController.text = textController.text;
        }

        fakeController.value = cm.activeChat!.controller;
      } else {
        await cm.setAllInactive();
        fakeController.value = null;
      }
    }
    if (checkDeleted && existingChat?.dateDeleted != null) {
      Chat.unDelete(existingChat!);
      // ignore: argument_type_not_assignable, return_of_invalid_type, invalid_assignment, for_in_of_invalid_element_type
      await chats.addChat(existingChat);
    }
    return existingChat;
  }

  Future<void> addressOnSubmitted() async {
    if (selectedSuggestionIndex >= 0 && await _selectSuggestionAt(selectedSuggestionIndex)) {
      return;
    }
    final text = addressController.text;
    if (text.isEmail || text.isPhoneNumber) {
      await addSelected(SelectedContact(
        displayName: text,
        address: text,
      ));
    } else if (filteredContacts.length == 1) {
      final possibleAddresses = [...filteredContacts.first.phones, ...filteredContacts.first.emails];
      if (possibleAddresses.length == 1) {
        await addSelected(SelectedContact(
          displayName: filteredContacts.first.displayName,
          address: possibleAddresses.first,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: ss.settings.immersiveMode.value
            ? Colors.transparent
            : context.theme.colorScheme.background, // navigation bar color
        systemNavigationBarIconBrightness: context.theme.colorScheme.brightness.opposite,
        statusBarColor: Colors.transparent, // status bar color
        statusBarIconBrightness: context.theme.colorScheme.brightness.opposite,
      ),
      child: Scaffold(
        backgroundColor: ss.settings.windowEffect.value != WindowEffect.disabled
            ? Colors.transparent
            : context.theme.colorScheme.background,
        appBar: PreferredSize(
          preferredSize: Size(ns.width(context), kIsDesktop ? 90 : 50),
          child: AppBar(
            systemOverlayStyle: context.theme.colorScheme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            toolbarHeight: kIsDesktop ? 90 : 50,
            elevation: 0,
            scrolledUnderElevation: 3,
            surfaceTintColor: context.theme.colorScheme.primary,
            leading: buildBackButton(context),
            backgroundColor: Colors.transparent,
            centerTitle: ss.settings.skin.value == Skins.iOS,
            title: Text(
              "New Conversation",
              style: context.theme.textTheme.titleLarge,
            ),
            actions: [
              if (!canCreateGroupChats)
                IconButton(
                  icon: Icon(iOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline,
                      color: context.theme.colorScheme.error),
                  onPressed: () {
                    showDialog(
                        barrierDismissible: false,
                        context: Get.context!,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              "Group Chat Creation",
                              style: context.theme.textTheme.titleLarge,
                            ),
                            content: Text(
                                "Creating group chats from BlueBubbles is not possible on macOS 11 (Big Sur) and later due to limitations from Apple. You must setup the Private API to gain this feature.",
                                style: context.theme.textTheme.bodyLarge),
                            backgroundColor: context.theme.colorScheme.properSurface,
                            actions: <Widget>[
                              TextButton(
                                child: Text("Close",
                                    style: context.theme.textTheme.bodyLarge!
                                        .copyWith(color: context.theme.colorScheme.primary)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        });
                  },
                ),
            ],
          ),
        ),
        body: FocusScope(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                child: Row(
                  children: [
                    Text(
                      "To: ",
                      style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.outline),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: ThemeSwitcher.getScrollPhysics(),
                        controller: addressScrollController,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeIn,
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxHeight: context.theme.textTheme.bodyMedium!.fontSize! + 20),
                                child: Obx(() => ListView.builder(
                                      itemCount: selectedContacts.length,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const NeverScrollableScrollPhysics(),
                                      findChildIndexCallback: (key) => findChildIndexByKey(selectedContacts, key, (item) => item.address),
                                      itemBuilder: (context, index) {
                                        final e = selectedContacts[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                          child: Obx(() => Material(
                                                key: ValueKey(e.address),
                                                color: e.iMessage.value == true
                                                    ? context.theme.colorScheme.bubble(context, true).withOpacity(0.2)
                                                    : e.iMessage.value == false
                                                        ? context.theme.colorScheme
                                                            .bubble(context, false)
                                                            .withOpacity(0.2)
                                                        : context.theme.colorScheme.properSurface,
                                                borderRadius: BorderRadius.circular(5),
                                                clipBehavior: Clip.antiAlias,
                                                child: InkWell(
                                                  onTap: () {
                                                    removeSelected(e);
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.0),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: <Widget>[
                                                        Text(e.displayName,
                                                            style: context.theme.textTheme.bodyMedium!.copyWith(
                                                              color: e.iMessage.value == true
                                                                  ? context.theme.colorScheme.bubble(context, true)
                                                                  : e.iMessage.value == false
                                                                      ? context.theme.colorScheme.bubble(context, false)
                                                                      : context.theme.colorScheme.properOnSurface,
                                                            )),
                                                        const SizedBox(width: 5.0),
                                                        Icon(
                                                          iOS ? CupertinoIcons.xmark : Icons.close,
                                                          size: 15.0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )),
                                        );
                                      },
                                    )),
                              ),
                            ),
                            if (selectedContacts.isNotEmpty)
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: ns.width(context) - 50),
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent) {
                                    if (event.logicalKey == LogicalKeyboardKey.backspace &&
                                        (addressController.selection.start == 0 || addressController.text.isEmpty)) {
                                      if (selectedContacts.isNotEmpty) {
                                        removeSelected(selectedContacts.last);
                                      }
                                      return KeyEventResult.handled;
                                    } else if (!HardwareKeyboard.instance.isShiftPressed &&
                                        event.logicalKey == LogicalKeyboardKey.tab) {
                                      messageNode.requestFocus();
                                      return KeyEventResult.handled;
                                    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && _totalSuggestions > 0) {
                                      if (selectedSuggestionIndex >= _totalSuggestions - 1) {
                                        messageNode.requestFocus();
                                        return KeyEventResult.handled;
                                      }
                                      setState(() {
                                        previousSuggestionIndex = selectedSuggestionIndex;
                                        selectedSuggestionIndex = min(
                                          selectedSuggestionIndex < 0 ? 0 : selectedSuggestionIndex + 1,
                                          _totalSuggestions - 1,
                                        );
                                      });
                                      _scrollSelectedSuggestionIntoView();
                                      return KeyEventResult.handled;
                                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && _totalSuggestions > 0) {
                                      setState(() {
                                        previousSuggestionIndex = selectedSuggestionIndex;
                                        selectedSuggestionIndex = max(selectedSuggestionIndex - 1, 0);
                                      });
                                      _scrollSelectedSuggestionIntoView();
                                      return KeyEventResult.handled;
                                    } else if ((event.logicalKey == LogicalKeyboardKey.enter ||
                                            event.logicalKey == LogicalKeyboardKey.select) &&
                                        !HardwareKeyboard.instance.isShiftPressed) {
                                      addressOnSubmitted();
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextField(
                                  textCapitalization: TextCapitalization.sentences,
                                  focusNode: addressNode,
                                  autocorrect: false,
                                  controller: addressController,
                                  style: context.theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  selectionControls:
                                      iOS ? cupertinoTextSelectionControls : materialTextSelectionControls,
                                  autofocus: widget.initialAttachments.isEmpty && (widget.initialText?.isEmpty ?? true) && widget.initialSelected.isEmpty,
                                  enableIMEPersonalizedLearning: !ss.settings.incognitoKeyboard.value,
                                  textInputAction: TextInputAction.done,
                                  cursorColor: context.theme.colorScheme.primary,
                                  cursorHeight: context.theme.textTheme.bodyMedium!.fontSize! * 1.25,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    hintText: "Enter a name, number, or email...",
                                    hintStyle: context.theme.textTheme.bodyMedium!
                                        .copyWith(color: context.theme.colorScheme.outline),
                                  ),
                                  onSubmitted: (String value) {
                                    addressOnSubmitted();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (backend.supportsSmsForwarding())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0).add(const EdgeInsets.only(bottom: 5.0)),
                  child: ToggleButtons(
                    constraints: BoxConstraints(minWidth: (ns.width(context) - 35) / 2),
                    fillColor: context.theme.colorScheme.bubble(context, iMessage).withOpacity(0.2),
                    splashColor: context.theme.colorScheme.bubble(context, iMessage).withOpacity(0.2),
                    children: [
                      const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("iMessage"),
                          ),
                          Icon(CupertinoIcons.chat_bubble, size: 16),
                        ],
                      ),
                      const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Text Message"),
                          ),
                          Icon(Icons.messenger_outline, size: 16),
                        ],
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                    selectedBorderColor: context.theme.colorScheme.bubble(context, iMessage),
                    selectedColor: context.theme.colorScheme.bubble(context, iMessage),
                    isSelected: [iMessage, sms],
                    onPressed: (index) async {
                      selectedContacts.clear();
                      addressController.text = "";
                      if (index == 0) {
                        setState(() {
                          iMessage = true;
                          textController.supportsFormatting = true;
                          sms = false;
                          filteredChats = List<Chat>.from(existingChats.where((e) => e.isIMessage));
                        });
                        await cm.setAllInactive();
                        fakeController.value = null;
                      } else {
                        setState(() {
                          iMessage = false;
                          textController.supportsFormatting = false;
                          sms = true;
                          filteredChats = List<Chat>.from(existingChats.where((e) => !e.isIMessage));
                        });
                        await cm.setAllInactive();
                        fakeController.value = null;
                      }
                    },
                  ),
                ),
              Expanded(
                child: Theme(
                  data: context.theme.copyWith(
                    // in case some components still use legacy theming
                    primaryColor: context.theme.colorScheme.bubble(context, iMessage),
                    colorScheme: context.theme.colorScheme.copyWith(
                      primary: context.theme.colorScheme.bubble(context, iMessage),
                      onPrimary: context.theme.colorScheme.onBubble(context, iMessage),
                      surface: ss.settings.monetTheming.value == Monet.full
                          ? null
                          : (context.theme.extensions[BubbleColors] as BubbleColors?)?.receivedBubbleColor,
                      onSurface: ss.settings.monetTheming.value == Monet.full
                          ? null
                          : (context.theme.extensions[BubbleColors] as BubbleColors?)?.onReceivedBubbleColor,
                    ),
                  ),
                  child: Obx(() {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: fakeController.value == null
                          ? CustomScrollView(
                              shrinkWrap: true,
                              physics: ThemeSwitcher.getScrollPhysics(),
                              slivers: <Widget>[
                                SliverList(
                                  delegate: SliverChildBuilderDelegate((context, index) {
                                    if (filteredChats.isEmpty) {
                                      return chats.chats.isEmpty ? const SizedBox.shrink() : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Loading existing chats...",
                                              style: context.theme.textTheme.labelLarge,
                                            ),
                                          ),
                                          buildProgressIndicator(context, size: 15),
                                        ],
                                      );
                                    }
                                    final chat = filteredChats[index];
                                    final hideInfo =
                                        ss.settings.redactedMode.value && ss.settings.hideContactInfo.value;
                                    String _title = chat.properTitle;
                                    if (hideInfo) {
                                      _title =
                                          chat.participants.length > 1 ? "Group Chat" : chat.participants[0].fakeName;
                                    }
                                    final isSelectedSuggestion = selectedSuggestionIndex == index;
                                    return Material(
                                      key: _suggestionKey(index),
                                      color: isSelectedSuggestion ? context.theme.colorScheme.outline.withOpacity(0.2) : Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          addSelectedList(chat.participants
                                              .where((e) =>
                                                  selectedContacts.firstWhereOrNull((c) => c.address == e.address) ==
                                                  null)
                                              .map((e) => SelectedContact(
                                                    displayName: e.displayName,
                                                    address: e.address,
                                                    isIMessage: chat.isIMessage,
                                                  )));
                                        },
                                        child: ChatCreatorTile(
                                          key: ValueKey(chat.guid),
                                          title: _title,
                                          subtitle: hideInfo
                                              ? ""
                                              : !chat.isGroup && chat.participants.isNotEmpty
                                                  ? (chat.participants.first.formattedAddress ??
                                                      chat.participants.first.address)
                                                  : chat.getChatCreatorSubtitle(),
                                          chat: chat,
                                        ),
                                      ),
                                    );
                                  },
                                      childCount: filteredChats.length
                                          .clamp(chats.loadedAllChats.isCompleted ? 0 : 1, double.infinity)
                                          .toInt()),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                    final contact = filteredContacts[index];
                                    final phones = getUniqueNumbers(contact.phones);
                                    final emails = getUniqueEmails(contact.emails);
                                    contact.phones = phones;
                                    contact.emails = emails;
                                    final hideInfo =
                                        ss.settings.redactedMode.value && ss.settings.hideContactInfo.value;
                                    int suggestionOffset = filteredChats.length;
                                    for (int i = 0; i < index; i++) {
                                      suggestionOffset += getUniqueNumbers(filteredContacts[i].phones).length + getUniqueEmails(filteredContacts[i].emails).length;
                                    }
                                    return Column(
                                      key: ValueKey(contact.id),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          ...phones.asMap().entries.map((entry) => Material(
                                                key: _suggestionKey(suggestionOffset + entry.key),
                                                color: selectedSuggestionIndex == suggestionOffset + entry.key
                                                    ? context.theme.colorScheme.outline.withOpacity(0.2)
                                                    : Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (selectedContacts.firstWhereOrNull((c) => c.address == entry.value) !=
                                                        null) return;
                                                    addSelected(
                                                        SelectedContact(displayName: contact.displayName, address: entry.value));
                                                  },
                                                  child: ChatCreatorTile(
                                                    title: hideInfo ? "Contact" : contact.displayName,
                                                    subtitle: hideInfo ? "" : entry.value,
                                                    contact: contact,
                                                    format: true,
                                                  ),
                                                ),
                                              )),
                                          ...emails.asMap().entries.map((entry) => Material(
                                                key: _suggestionKey(suggestionOffset + phones.length + entry.key),
                                                color: selectedSuggestionIndex == suggestionOffset + phones.length + entry.key
                                                    ? context.theme.colorScheme.outline.withOpacity(0.2)
                                                    : Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (selectedContacts.firstWhereOrNull((c) => c.address == entry.value) !=
                                                        null) return;
                                                    addSelected(
                                                        SelectedContact(displayName: contact.displayName, address: entry.value));
                                                  },
                                                  child: ChatCreatorTile(
                                                    title: hideInfo ? "Contact" : contact.displayName,
                                                    subtitle: hideInfo ? "" : entry.value,
                                                    contact: contact,
                                                  ),
                                                ),
                                              )),
                                        ],
                                      );
                                    },
                                    childCount: filteredContacts.length,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: Colors.transparent,
                              child: MessagesView(
                                controller: fakeController.value!,
                              ),
                            ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5.0, top: 10.0, bottom: 5.0),
                child: Theme(
                  data: context.theme.copyWith(
                    // in case some components still use legacy theming
                    primaryColor: context.theme.colorScheme.bubble(context, iMessage),
                    colorScheme: context.theme.colorScheme.copyWith(
                      primary: context.theme.colorScheme.bubble(context, iMessage),
                      onPrimary: context.theme.colorScheme.onBubble(context, iMessage),
                      surface: ss.settings.monetTheming.value == Monet.full
                          ? null
                          : (context.theme.extensions[BubbleColors] as BubbleColors?)?.receivedBubbleColor,
                      onSurface: ss.settings.monetTheming.value == Monet.full
                          ? null
                          : (context.theme.extensions[BubbleColors] as BubbleColors?)?.onReceivedBubbleColor,
                    ),
                  ),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          HardwareKeyboard.instance.isShiftPressed &&
                          event.logicalKey == LogicalKeyboardKey.tab) {
                        addressNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Obx(() => TextFieldComponent(
                        focusNode: messageNode,
                        textController: textController,
                        controller: fakeController.value,
                        recorderController: null,
                        initialAttachments: widget.initialAttachments,
                        sendMessage: ({String? effect}) async {
                          if (selectedContacts.isEmpty) {
                            showSnackbar("Error!", "Choose a contact before sending this message!");
                            return;
                          }
                          if (addressController.text.trim() != "") {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    title: Text(
                                      "Querying available services...",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    content: Container(
                                      height: 70,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          backgroundColor: context.theme.colorScheme.properSurface,
                                          valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                            await addressOnSubmitted();
                            Get.back(closeOverlays: true);
                          }
                          final chat = fakeController.value?.chat ?? await findExistingChat(checkDeleted: true, update: false);
                          bool existsOnServer = true; // if there is no remote, we exist on the "server"
                          if (chat != null && backend.getRemoteService() != null) {
                            // if we don't error, then the chat exists
                            try {
                              await backend.getRemoteService()!.singleChat(chat.guid);
                            } catch (_) {
                              existsOnServer = false;
                            }
                          }
                          if (!iMessage && ss.settings.smsForwardingTargets.keys.isEmpty) {
                            // we have no one to sms forward to, open the default messaging app
                            if (kIsDesktop) {
                              showSnackbar("Someone's not on iMessage!", "Enable SMS forwarding on another device!");
                              return;
                            }

                            if (!ss.settings.warnedTextChats.value) {
                              await showDialog(
                                context: Get.context!,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Text chats open in Messages",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    content: Text(
                                      "You will be sent to your default messaging app if iMessage isn't supported by all participants.",
                                      style: context.theme.textTheme.bodyLarge
                                    ),
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text("Ok",
                                            style: context.theme.textTheme.bodyLarge!
                                                .copyWith(color: context.theme.colorScheme.primary)),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          ss.settings.warnedTextChats.value = true;
                                          ss.saveSettings();
                                        },
                                      ),
                                    ],
                                  );
                                });
                            }
                            
                            final participants = selectedContacts
                                .map((e) => e.address.isEmail ? e.address : cleansePhoneNumber(e.address))
                                .toList();
                            mcs.invokeMethod("open-sms-app", {
                              "targets": participants.join(";"),
                              "body": textController.text
                            });
                            Navigator.of(context).pop();
                            return;
                          }
                          if (chat != null && existsOnServer) {
                            sendInitialMessage() async {
                              try {
                                if (fakeController.value == null) {
                                  await cm.setActiveChat(chat, clearNotifications: false);
                                  cm.activeChat!.controller = cvc(chat);
                                  cm.activeChat!.controller!.pickedAttachments.value = [];
                                  fakeController.value = cm.activeChat!.controller;
                                } else {
                                  fakeController.value!.textController.text = textController.text;
                                  fakeController.value!.pickedAttachments.value = widget.initialAttachments;
                                }
                              } catch (e, stack) {
                                Logger.error("Fix your code zach!", error: e, trace: stack);
                              }

                              await fakeController.value!.send(
                                widget.initialAttachments,
                                fakeController.value!.textController.getFinalAnnotations(),
                                "",
                                fakeController.value!.replyToMessage?.item1.threadOriginatorGuid ??
                                    fakeController.value!.replyToMessage?.item1.guid,
                                fakeController.value!.replyToMessage?.item2,
                                effect,
                                null,
                                false,
                                null,
                              );
                              
                              try {
                                fakeController.value!.replyToMessage = null;
                                fakeController.value!.pickedAttachments.clear();
                                fakeController.value!.textController.clear();
                                fakeController.value!.subjectTextController.clear();
                              } catch (e, stack) {
                                Logger.error("Fix your code zach!", error: e, trace: stack);
                              }
                            }

                            if (backend is RustPushBackend && widget.initialAttachments.isEmpty && widget.initialText == "") {
                              var b = backend as RustPushBackend;
                              var handle = iMessage ? await b.getDefaultHandle() : await b.getDefaultSMSHandle();
                              chat.usingHandle = handle;
                              chat.save(updateUsingHandle: true);
                            }
                            ns.pushAndRemoveUntil(
                              Get.context!,
                              ConversationView(chat: chat, fromChatCreator: true, onInit: sendInitialMessage),
                              (route) => route.isFirst,
                              // don't force close the active chat in tablet mode
                              closeActiveChat: false,
                              // only used in non-tablet mode context
                              customRoute: PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    TitleBarWrapper(child: ConversationView(chat: chat, fromChatCreator: true, onInit: sendInitialMessage)),
                                transitionDuration: Duration.zero,
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 500));
                            
                          } else {
                            if (!(createCompleter?.isCompleted ?? true)) return;
                            // hard delete a chat that exists on BB but not on the server to make way for the proper server data
                            if (chat != null) {
                              chats.removeChat(chat);
                              Chat.deleteChat(chat);
                            }
                            createCompleter = Completer();
                            final participants = selectedContacts
                                .map((e) => e.address.isEmail ? e.address : cleansePhoneNumber(e.address))
                                .toList();
                            final method = iMessage ? "iMessage" : "SMS";
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    title: Text(
                                      "Creating a new $method chat...",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    content: Container(
                                      height: 70,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          backgroundColor: context.theme.colorScheme.properSurface,
                                          valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                            backend.createChat(participants.map((i) => RustPushBBUtils.formatAddress(i)).toList(), textController.getFinalAnnotations(), method).then((newChat) async {
                              newChat.senderIsKnown = true;
                              // Load the chat data and save it to the DB
                              newChat = newChat.save(updateSenderIsKnown: true);

                              // Fetch the newly saved chat data from the DB
                              // Throw an error if it wasn't saved correctly.
                              final saved = await cm.fetchChat(newChat.guid);
                              if (saved == null) {
                                return showSnackbar("Error", "Failed to save chat!");
                              }

                              // Update the chat in the chat list.
                              // If it wasn't existing, add it.
                              newChat = saved;
                              bool updated = chats.updateChat(newChat);
                              if (!updated) {
                                await chats.addChat(newChat);
                              }

                              // Fetch the last message for the chat and save it.
                              final messageRes = await backend.getRemoteService()?.chatMessages(newChat.guid, limit: 1);
                              if (messageRes != null && messageRes.data["data"].length > 0) {
                                final messages = (messageRes.data["data"] as List<dynamic>).map((e) => Message.fromMap(e)).toList();
                                await Chat.bulkSyncMessages(newChat, messages);
                              }

                              // Force close the message service for the chat so it can be reloaded.
                              // If this isn't done, new messages will not show.
                              ms(newChat.guid).close(force: true);
                              cvc(newChat).close();

                              // Let awaiters know we completed
                              createCompleter?.complete();

                              // Navigate to the new chat
                              Get.back(closeOverlays: true);
                              ns.pushAndRemoveUntil(
                                Get.context!,
                                ConversationView(chat: newChat),
                                (route) => route.isFirst,
                                customRoute: PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => TitleBarWrapper(
                                    child: ConversationView(
                                      chat: newChat,
                                      fromChatCreator: true,
                                    ),
                                  ),
                                  transitionDuration: Duration.zero,
                                ),
                              );
                            }).catchError((error) {
                              Get.back(closeOverlays: true);
                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: context.theme.colorScheme.properSurface,
                                      title: Text(
                                        "Failed to create chat!",
                                        style: context.theme.textTheme.titleLarge,
                                      ),
                                      content: Text(
                                        error is Response
                                            ? "Reason: (${error.data["error"]["type"]}) -> ${error.data["error"]["message"]}"
                                            : error.toString(),
                                        style: context.theme.textTheme.bodyLarge,
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text("OK",
                                              style: context.theme.textTheme.bodyLarge!
                                                  .copyWith(color: Get.context!.theme.colorScheme.primary)),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ],
                                    );
                                  });
                              if (!createCompleter!.isCompleted) {
                                createCompleter?.completeError(error);
                              }
                            });
                          }
                        })),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
