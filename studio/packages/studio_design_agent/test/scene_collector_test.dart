import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:studio_design_agent/studio_design_agent.dart';
import 'package:studio_protocol/studio_protocol.dart';

/// The tree that the tests pump. Each widget is alone on its line, so that
/// a test finds the line of a widget by the text of the line.
Widget _sampleTree() => const Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(key: Key('box'), width: 120, height: 40),
  ),
);

void main() {
  group('SceneCollector', () {
    final testFile = File(path.join('test', 'scene_collector_test.dart'));
    final lines = testFile.readAsLinesSync();

    /// Returns where the first line that has [text] has it.
    Position positionOf(String text) {
      final line = lines.indexWhere((each) => each.contains(text));
      return Position(line: line, character: lines[line].indexOf(text));
    }

    late Scene scene;

    Future<void> collect(WidgetTester tester) async {
      await tester.pumpWidget(_sampleTree());
      scene = SceneCollector(tester.binding, [
        '${Directory.current.uri}',
      ]).collect();
    }

    // Verifies: FR-CNV-006, IR-004
    testWidgets('finds each widget of the project where it is created', (
      tester,
    ) async {
      await collect(tester);

      expect(scene.elements.map((element) => element.className), [
        'Directionality',
        'Align',
        'SizedBox',
      ]);
      expect(scene.elements.map((element) => element.position), [
        positionOf('Directionality('),
        positionOf('Align('),
        positionOf('SizedBox('),
      ]);
      expect(
        scene.elements.every(
          (element) => element.uri == '${testFile.absolute.uri}',
        ),
        isTrue,
      );
    });

    // Verifies: FR-CNV-006
    testWidgets('reports the bounds of each element on the surface', (
      tester,
    ) async {
      await collect(tester);
      final box = scene.elements.last;
      final expected = tester.getRect(find.byKey(const Key('box')));

      expect(Rect.fromLTWH(box.left, box.top, box.width, box.height), expected);
      expect(
        scene.width,
        tester.view.physicalSize.width / scene.devicePixelRatio,
      );
    });

    // Verifies: FR-CNV-006
    testWidgets('links each element to its nearest ancestor in the scene', (
      tester,
    ) async {
      await collect(tester);

      expect(scene.elements.map((element) => element.parentIndex), [-1, 0, 1]);
    });

    // Verifies: FR-INS-004
    testWidgets('leaves out the widgets created outside the project', (
      tester,
    ) async {
      await tester.pumpWidget(_sampleTree());
      final collector = SceneCollector(tester.binding, ['file:///elsewhere/']);

      expect(collector.collect().elements, isEmpty);
      // The second scene takes the locations from what the first one read.
      expect(collector.collect().elements, isEmpty);
    });

    // Verifies: FR-PRP-011
    testWidgets('reports the constraints and the flex data of a widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [Expanded(flex: 2, child: SizedBox(height: 10))],
          ),
        ),
      );

      final elements = SceneCollector(tester.binding, [
        '${Directory.current.uri}',
      ]).collect().elements;
      final row = elements[1].layout;
      final box = elements.last.layout;

      expect(elements.last.className, 'SizedBox');
      expect((row?.minWidth, row?.maxWidth, row?.flex), (800, 800, null));
      expect(box?.flex, 2);
      expect(box?.fit, FlexFitKind.tight);
      expect((box?.minWidth, box?.maxWidth), (800, 800));
      expect(box?.maxHeight, 600);
    });
  });
}
