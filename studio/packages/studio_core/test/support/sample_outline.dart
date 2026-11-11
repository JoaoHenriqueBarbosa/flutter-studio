/// Source that the outline of [sampleOutline] describes.
const sampleOutlineSource = '''
class Page {
  build() {
    return const Center(
      child: Column(children: [new Text('a'), Builder(builder: (c) {
        go() => Icon(i);
        return go();
      })]),
    );
  }
}
''';

Map<String, Object?> _node(
  int line,
  int character, {
  String? className,
  String? elementName,
  List<Map<String, Object?>> children = const [],
}) => {
  'range': {
    'start': {'line': line, 'character': character},
    'end': {'line': line, 'character': character + 1},
  },
  'className': ?className,
  if (elementName != null) 'dartElement': {'name': elementName},
  'children': children,
};

/// The Flutter Outline of [sampleOutlineSource], in the JSON form of the
/// analysis server.
Map<String, Object?> get sampleOutline => _node(
  0,
  0,
  elementName: '<unit>',
  children: [
    _node(
      0,
      0,
      elementName: 'Page',
      children: [
        _node(
          1,
          2,
          elementName: 'build',
          children: [
            _node(
              2,
              11,
              className: 'Center',
              children: [
                _node(
                  3,
                  13,
                  className: 'Column',
                  children: [
                    _node(3, 31, className: 'Text'),
                    _node(
                      3,
                      46,
                      className: 'Builder',
                      children: [
                        _node(
                          4,
                          8,
                          elementName: 'go',
                          children: [_node(4, 16, className: 'Icon')],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
