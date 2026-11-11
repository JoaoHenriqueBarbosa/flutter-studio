import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';
import 'package:studio_protocol/studio_protocol.dart';

SceneElement _element(int line, List<double> rect, {int parentIndex = -1}) =>
    SceneElement(
      className: 'Column',
      uri: 'file:///work/lib/main.dart',
      position: Position(line: line, character: 4),
      parentIndex: parentIndex,
      left: rect[0],
      top: rect[1],
      width: rect[2],
      height: rect[3],
    );

void main() {
  group('SceneGeometry', () {
    final geometry = SceneGeometry(
      Scene(
        width: 800,
        height: 600,
        devicePixelRatio: 3,
        elements: [
          _element(1, [0, 0, 800, 600]),
          _element(2, [100, 100, 200, 200], parentIndex: 0),
          _element(3, [150, 150, 50, 20], parentIndex: 1),
          _element(3, [150, 180, 50, 20], parentIndex: 1),
        ],
      ),
    );

    SourceLocation at(int line) =>
        (filePath: '/work/lib/main.dart', position: (line: line, character: 4));

    // Verifies: FR-CNV-006, FR-INS-003
    test('finds the deepest element under a point', () {
      expect(geometry.locationAt(160, 160), at(3));
      expect(geometry.locationAt(110, 110), at(2));
      expect(geometry.locationAt(10, 10), at(1));
    });

    // Verifies: FR-CNV-006
    test('finds nothing outside every element', () {
      expect(geometry.locationAt(900, 10), isNull);
    });

    // Verifies: FR-CNV-006, FR-INS-005
    test('finds every element that one location creates', () {
      expect(geometry.elementsCreatedAt(at(3)), hasLength(2));
      expect(geometry.elementsCreatedAt(at(2)).single.left, 100);
      expect(geometry.elementsCreatedAt(at(9)), isEmpty);
    });
  });
}
