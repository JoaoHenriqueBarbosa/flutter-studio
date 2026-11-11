# studio_shell

Desktop shell of Studio. It is the only package with a platform runner and the
only one that imports `devtools_app` (see section 6.1 of the coding standard).

The inherited DevTools code loads its assets and fonts as if it were the root
application. The `inherited_assets` library resolves those requests inside the
shell bundle (ADR-0015).

Build and run with the Flutter version pinned in `studio/flutter-version.txt`:

```sh
flutter run -d linux --dart-entrypoint-args /path/to/a/flutter/project
```

The Studio screen opens the project, runs its app and shows the widget tree of
the inherited inspector beside the inherited property editor. A value changed
in the property editor is written to the code of the project, and the app is
reloaded.
