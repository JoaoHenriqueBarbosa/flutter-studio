import 'package:devtools_app/devtools_app.dart';
import 'package:material_ui/material_ui.dart';

/// The screen of DevTools that hosts the workbench of Studio.
final class StudioScreen extends Screen {
  /// Creates the screen whose body is built by [_buildBody].
  ///
  /// The body comes as a builder because the screens are declared before
  /// DevTools creates the managers that the workbench depends on.
  const StudioScreen(this._buildBody)
    : super(
        id,
        title: _productName,
        icon: Icons.design_services_outlined,
        requiresConnection: false,
      );

  /// Identifier of the screen in the DevTools route.
  static const id = 'studio';

  /// Name of the product, which is not translated.
  static const _productName = 'Studio';

  final WidgetBuilder _buildBody;

  @override
  Widget buildScreenBody(BuildContext context) => _buildBody(context);
}
