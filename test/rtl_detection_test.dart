import 'package:bluebubbles/helpers/ui/text_direction_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('farsi text detected as RTL', () {
    expect(getTextDirection('سلام'), TextDirection.rtl);
    expect(getTextDirection('سلام 😂'), TextDirection.rtl);
    expect(getTextDirection('چطوری، خوبی؟'), TextDirection.rtl);
  });
  test('emoji/punctuation-leading farsi detected as RTL (first strong char)', () {
    expect(getTextDirection('😂 سلام'), TextDirection.rtl);
    expect(getTextDirection('"سلام"'), TextDirection.rtl);
    expect(getTextDirection('۱۲۳ سلام'), TextDirection.rtl);
  });
  test('english stays LTR', () {
    expect(getTextDirection('hello'), TextDirection.ltr);
    expect(getTextDirection('hello 😂'), TextDirection.ltr);
    expect(getTextDirection('😂 hello'), TextDirection.ltr);
    expect(getTextDirection(''), TextDirection.ltr);
    expect(getTextDirection(null), TextDirection.ltr);
  });
  test('mixed first-strong wins', () {
    expect(getTextDirection('سلام hello'), TextDirection.rtl);
    expect(getTextDirection('hello سلام'), TextDirection.ltr);
  });
}
