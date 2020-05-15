# Jackbox Flutter Client

A re-implementation of some Jackbox front-end features in a Flutter client. Initially aimed at Drawful.

## Getting Started

Build the client as per usual for Flutter web

```
flutter build web
```

Then find output in the `build/web` directory.

## Things that don't work

* Rejected lies because they match up with something else
* Liking a choice is a bit buggy and will duplicate items in the list
* Everything looks like garbage
* Imported drawings don't display on the canvas but do submit correctly
