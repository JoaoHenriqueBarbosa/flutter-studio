# studio_package_assets

Lets code written as a root application keep finding its assets and fonts when
its package runs as a dependency of another application (ADR-0015, ADR-0016).
The shell uses it for the inherited `devtools_app`, and the design agent uses it
for the project of the user inside the host project. It depends only on the
Flutter SDK and is compiled with the SDK of the project as well.
