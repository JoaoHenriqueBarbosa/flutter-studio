# studio_design_agent

The design agent of Studio: the code that runs inside the app of the project and
tells the shell what is on screen (IF-06). It depends only on the Flutter SDK and
on `studio_protocol`, and it is compiled with the SDK of the project, so it uses
no feature newer than the oldest supported Flutter.
