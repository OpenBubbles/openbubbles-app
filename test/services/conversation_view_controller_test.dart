import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dismissKeyboard releases the conversation composer focus', (tester) async {
    final controller = ConversationViewController(Chat(guid: 'iMessage;-;keyboard-test'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(focusNode: controller.focusNode),
        ),
      ),
    );
    controller.focusNode.requestFocus();
    await tester.pump();
    expect(controller.focusNode.hasFocus, isTrue);

    controller.dismissKeyboard();
    await tester.pump();

    expect(controller.focusNode.hasFocus, isFalse);
  });
}
