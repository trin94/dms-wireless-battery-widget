<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# Project commands

- Checkout common commands by running the command `just`.
- Run linter and formatter via `just fmt`.

## Domain

- The ubiquitous language lives in `CONTEXT.md`. Use its terms in code, tests, and docs, and
  respect the *Avoid* lists.
- Architectural decisions live in `docs/adr/`. Read them before changing structure; record new
  ones in the same format.

## Coding

- Follow clean code principles.
- Don't use structural comments like `# region` or `# ---`.
- Avoid comments unless absolutely necessary.
- Use the `signal name(value: type)` notation instead of the old `signal name(type value)` notation in QML signals.
- `src/qml` holds only the entry points referenced in `plugin.json`. Pure logic components live
  in `src/qml/logic` together with their tests, visual components in `src/qml/views`.
- List every new QML component in the `qmldir` of its directory. The qmldir enables the
  singletons and shadows the implicit directory type resolution.
- Follow official QML coding conventions.
- Respect the recommended QML file layout:
  01. id
  02. Required properties
  03. Aliases (property alias / readonly property alias)
  04. Readonly value properties (public)
  05. Mutable properties (public)
  06. Private properties (underscore-prefixed)
  07. Signal declarations
  08. Enums (none here)
  09. JavaScript functions (none here)
  10. Own object property bindings (height, width, anchors, color, etc.)
  11. Attached property bindings (Material. *, ListView.* bindings, Layout.\*)
  12. Property change handlers (onXChanged)
  13. Attached signal handlers (ListView.onPooled/onReused, Component.onCompleted/onDestruction, Keys.onPressed)
  14. Child objects (visual children)
  15. Behaviors
  16. States
  17. Transitions

## Committing

- Run all pre-commit hooks via `just fmt` to confirm everything's fine before committing.
- Verify the documentation is up to date before committing.
- Use the [Conventional Commits](https://www.conventionalcommits.org/) format.
