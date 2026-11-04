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
import 'package:bluebubbles/src/rust/api/api.dart' as api;

class SelectedContact {
  final String displayName;
  final String address;
  late final RxnBool iMessage;

  SelectedContact({required this.displayName, required this.address, bool? isIMessage}) {
    iMessage = RxnBool(isIMessage);
  }
}

class GroupInviteCreator extends StatefulWidget {
  const GroupInviteCreator({
    super.key,
    this.initialText = "",
    this.initialAttachments = const [],
    this.initialSelected = const [],
  });

  final String? initialText;
  final List<PlatformFile> initialAttachments;
  final List<SelectedContact> initialSelected;

  @override
  GroupInviteCreatorState createState() => GroupInviteCreatorState();
}

class GroupInviteCreatorState extends OptimizedState<GroupInviteCreator> {
  final TextEditingController addressController = TextEditingController();
  final messageNode = FocusNode();
  late final MentionTextEditingController textController = MentionTextEditingController(text: widget.initialText, focusNode: messageNode);
  final FocusNode addressNode = FocusNode();
  final ScrollController addressScrollController = ScrollController();

  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  late final RxList<SelectedContact> selectedContacts = List<SelectedContact>.from(widget.initialSelected).obs;
  final Rxn<ConversationViewController> fakeController = Rxn(null);
  bool iMessage = true;
  bool sms = false;
  String? oldText;
  ConversationViewController? oldController;
  Timer? _debounce;
  Completer<void>? createCompleter;

  @override
  void initState() {
    super.initState();

    addressController.addListener(() {
      _debounce?.cancel();
      Logger.debug("right app");
      _debounce = Timer(const Duration(milliseconds: 250), () async {
        final tuple = await SchedulerBinding.instance.scheduleTask(() async {
          // If you type and then delete everything, show selected chat view
          if (addressController.text.isEmpty && selectedContacts.isNotEmpty) {
            await findExistingChat();
            return Tuple2(contacts, []);
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
          return Tuple2(_contacts, []);
        }, Priority.animation);
        _debounce = null;
        setState(() {
          filteredContacts = List<Contact>.from(tuple.item1);
        });
      });
    });

    updateObx(() {
      if (widget.initialAttachments.isEmpty && !kIsWeb) {
        final query = (Database.contacts.query()..order(Contact_.displayName)).build();
        contacts = query.find().toSet().toList();
        filteredContacts = List<Contact>.from(contacts);
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
    var handle = backend is RustPushBackend ? await (backend as RustPushBackend).getDefaultHandle() : ss.settings.defaultHandle.value;
    try {
      var target = await RustPushBBUtils.formatAndAddPrefix(c.address);
      c.iMessage.value = await api.queryHandle(
        passwords: pushService.state!.icloudServices!.passwords!,
        handle: target,
      );
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

  Future<void> findExistingChat({bool checkDeleted = false, bool update = true}) async {
    // no selected items, remove message view
    if (selectedContacts.isEmpty) {
      await cm.setAllInactive();
      fakeController.value = null;
      return;
    }
    if (selectedContacts.any((element) => element.iMessage.value == false)) {
      setState(() {
        iMessage = false;
        sms = true;
      });
    } else {
      setState(() {
        iMessage = true;
        sms = false;
      });
    }
  }

  Future<void> addressOnSubmitted() async {
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
              "Add members",
              style: context.theme.textTheme.titleLarge,
            ),
            actions: [],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: context.theme.colorScheme.bubble(context, false),
          shape: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2),
            child: Icon(
              CupertinoIcons.add,
              color: context.theme.colorScheme.onBubble(context, false),
              size: 30,
            ),
          ),
          onPressed: () async {
            if (selectedContacts.any((s) => s.iMessage.value == false)) {
              showSnackbar("Error", "At least one selected user doesn't support passwords!");
              return;
            }
            List<String> targets = [];
            for (var user in selectedContacts) {
              targets.add(await RustPushBBUtils.formatAndAddPrefix(user.address));
            }
            if (!mounted) return;
            Navigator.of(context).pop(targets);
          },
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
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final contact = filteredContacts[index];
                                      contact.phones = getUniqueNumbers(contact.phones);
                                      contact.emails = getUniqueEmails(contact.emails);
                                      final hideInfo =
                                          ss.settings.redactedMode.value && ss.settings.hideContactInfo.value;
                                      return Column(
                                        key: ValueKey(contact.id),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ...contact.phones.map((e) => Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (selectedContacts.firstWhereOrNull((c) => c.address == e) !=
                                                        null) return;
                                                    addSelected(
                                                        SelectedContact(displayName: contact.displayName, address: e));
                                                  },
                                                  child: ChatCreatorTile(
                                                    title: hideInfo ? "Contact" : contact.displayName,
                                                    subtitle: hideInfo ? "" : e,
                                                    contact: contact,
                                                    format: true,
                                                  ),
                                                ),
                                              )),
                                          ...contact.emails.map((e) => Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (selectedContacts.firstWhereOrNull((c) => c.address == e) !=
                                                        null) return;
                                                    addSelected(
                                                        SelectedContact(displayName: contact.displayName, address: e));
                                                  },
                                                  child: ChatCreatorTile(
                                                    title: hideInfo ? "Contact" : contact.displayName,
                                                    subtitle: hideInfo ? "" : e,
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
            ],
          ),
        ),
      ),
    );
  }
}
