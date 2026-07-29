import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestController extends StatefulController {}

class _TestWidget extends CustomStateful<_TestController> {
  const _TestWidget({required super.parentController});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends CustomState<_TestWidget, void, _TestController> {
  @override
  void initState() {
    forceDelete = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('rebinds updates when a retained controller row is remounted', (tester) async {
    final controller = _TestController();

    await tester.pumpWidget(MaterialApp(home: _TestWidget(parentController: controller)));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(MaterialApp(home: _TestWidget(parentController: controller)));

    expect(tester.takeException(), isNull);
  });
}
