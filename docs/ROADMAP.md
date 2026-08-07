# Roadmap

## M0 - Engineering foundation

Status: in progress

- Swift 6 package structure
- native macOS app bootstrap
- deterministic notch geometry model
- compact/expanded panel state
- automated unit tests
- CI build/test/package pipeline
- ad-hoc `.app` and `.dmg` packaging
- project architecture/state documentation

Exit criteria: CI is green and a DMG artifact is produced from a pull request.

## M1 - Notch Core

- reliable hover and click interaction
- tuned expansion/collapse animation
- delayed collapse to avoid pointer flicker
- multiple displays and active-screen migration
- fullscreen/Space behavior
- screen-configuration change handling
- visual regression/manual acceptance checklist for real hardware

## M2 - Shelf

- accept files via drag and drop
- drag files back into other apps
- preserve source files; removing from Shelf never deletes the source
- stale-reference handling
- optional automatic cleanup

## M3 - Snippets

- local snippet store
- groups and search
- copy to clipboard
- optional direct paste behind explicit Accessibility permission
- privacy mode for screen sharing

## M4 - Calendar

- EventKit integration
- next-event view
- permission states and graceful denial handling
- upcoming-event compact indicator

## M5 - Translator

- Apple Translation framework integration where available
- automatic source-language handling
- copy result and swap languages
- optional clipboard translation

## M6 - Media / Yandex Music

- provider abstraction and fake provider tests
- Yandex Music desktop compatibility probe
- track metadata and artwork
- play/pause, previous, next
- timeline/progress where available
- isolated MediaRemote fallback for personal builds if required
- compatibility tests across macOS updates

## M7 - Product shell

- settings
- global shortcuts
- launch at login
- module ordering and enable/disable controls
- accessibility and reduced-motion behavior

## M8 - Release hardening

- Developer ID signing
- Apple notarization
- version stamping
- release notes
- stable DMG release workflow
