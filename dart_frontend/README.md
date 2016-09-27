# Australian Election front end

To develop, install [Dartlang](https://www.dartlang.org/downloads/).
Once all that is sorted, then:

```bash
$ cd dart_frontend
$ pub get
$ pub global activate grinder # Used in Makefile to format code and transcompile to JS
```

Grind is installed in `$HOME/.pub-cache/bin`. Please add this to your PATH.

To do local development, edit `apiBaseUrl` in `lib/configuration.dart` to point
to an app engine instance with the API serving with CORS headers, and then:

```bash
$ pub serve &
$ open http://localhost:8080/
```

To publish, first change `apiBaseUrl` in `lib/configuration.dart` to `/`, then
build and deploy:

```bash
$ make install
$ goapp deploy ../app/app.yaml
```

## Suggested tooling

The [Atom editor](https://atom.io/) with the
[dartlang package](https://atom.io/packages/dartlang). Install
[atom](https://atom.io/), then install `dartlang`, either in the Preferences
pane (Atom|Preferences...), or from the command line:

```bash
$ apm install dartlang
```

This gives you syntax highlighting, code hints, and click to navigate. When the
underlying `dart` analyzer gets confused,  re-analyze sources
(Packages|Dart|Re-analyze sources), and if that fails,
re-start the analyzer (Packages|Dart|Analysis Server Status|Shutdown;Start).

## Package docs

For dart's standard library - things imported like `import 'dart:foo';` there
is the [API Reference](https://api.dartlang.org/stable/1.16.1/index.html). For
third party dependencies installed via [pub](https://pub.dartlang.org/), there
is [dartdocs](https://www.dartdocs.org/). Of particular interest in this project:
 * [Google Maps](https://www.dartdocs.org/documentation/google_maps/3.1.0/)
 * [Firebase](https://www.dartdocs.org/documentation/firebase/0.6.6%2B1/)
 * [Angular2 for Dart](https://angular.io/docs/dart/latest/index.html)
