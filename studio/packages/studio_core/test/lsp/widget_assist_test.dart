import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  group('WidgetAssist', () {
    // Verifies: FR-STR-001
    test('names the wrap of a widget class as the server does', () {
      expect(
        WidgetAssist.wrapWith('SizedBox').kind,
        'refactor.flutter.wrap.sizedBox',
      );
    });

    // Verifies: FR-STR-001
    test('reads the widget class back from a wrap', () {
      expect(
        const WidgetAssist('refactor.flutter.wrap.sizedBox').wrapperClassName,
        'SizedBox',
      );
      expect(
        const WidgetAssist('refactor.flutter.wrap.generic').wrapperClassName,
        isNull,
      );
      expect(WidgetAssist.remove.wrapperClassName, isNull);
    });
  });
}
