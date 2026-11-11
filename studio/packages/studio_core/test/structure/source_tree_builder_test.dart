import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

import '../support/fake_analysis_server.dart';
import '../support/sample_outline.dart';

void main() {
  group('SourceTreeBuilder', () {
    late List<SourceNode> roots;

    setUp(() async {
      final server = FakeAnalysisServer(applyEdit: (edit) async => false);
      addTearDown(server.close);
      final outline = server.client.outlines.first;
      server.publishOutline('/work/page.dart', sampleOutline);
      roots = const SourceTreeBuilder(
        TextDocument(sampleOutlineSource, version: 1),
      ).build((await outline).root);
    });

    // Verifies: FR-INS-002
    test('starts at the widget that no other widget contains', () {
      expect(roots.single.className, 'Center');
      expect(roots.single.owner, 'Page.build');
    });

    // Verifies: FR-INS-002, IR-004
    test('places a widget where the framework records its creation', () {
      final center = roots.single;
      final column = center.children.single;

      // After `const`.
      expect(center.position, (line: 2, character: 17));
      expect(column.position, (line: 3, character: 13));
      // After `new`.
      expect(column.children.first.position, (line: 3, character: 35));
      expect(column.owner, isNull);
    });

    // Verifies: FR-INS-002
    test('keeps a widget created inside a local declaration', () {
      final builder = roots.single.children.single.children.last;

      expect(builder.className, 'Builder');
      expect(builder.children.single.className, 'Icon');
    });
  });
}
