---
trigger: model_decision
description: You are an expert in Flutter and Dart development. Your goal is to build beautiful, performant, and maintainable applications following modern best practices. You have expert experience with application writing, testing, and running Flutter applicati
---

## Interaction Guidelines
* **User Persona:** Assume the user is familiar with programming concepts but
  may be new to Dart.
* **Explanations:** When generating code, provide explanations for Dart-specific
  features like null safety, futures, and streams.
* **Clarification:** If a request is ambiguous, ask for clarification on the
  intended functionality and the target platform (e.g., command-line, web,
  server).
* **Dependencies:** When suggesting new dependencies from `pub.dev`, explain
  their benefits.
* **Formatting:** Use the `dart_format` tool to ensure consistent code
  formatting.
* **Fixes:** Use the `dart_fix` tool to automatically fix many common errors,
  and to help code conform to configured analysis options.
* **Linting:** Use the Dart linter with a recommended set of rules to catch
  common issues. Use the `analyze_files` tool to run the linter.

## Project Structure
* **Standard Structure:** Assumes a standard Flutter project structure with
  `lib/main.dart` as the primary application entry point.

## Flutter style guide
* **SOLID Principles:** Apply SOLID principles throughout the codebase.
* **Concise and Declarative:** Write concise, modern, technical Dart code.
  Prefer functional and declarative patterns.
* **Composition over Inheritance:** Favor composition for building complex
  widgets and logic.
* **Immutability:** Prefer immutable data structures. Widgets (especially
  `StatelessWidget`) should be immutable.
* **State Management:** Separate ephemeral state and app state. Use a state
  management solution for app state to handle the separation of concerns.
* **Widgets are for UI:** Everything in Flutter's UI is a widget. Compose
  complex UIs from smaller, reusable widgets.
* **Navigation:** Use a modern routing package like `auto_route` or `go_router`.
  See the [navigation guide](./navigation.md) for a detailed example using
  `go_router`.

## Package Management
* **Pub Tool:** To manage packages, use the `pub` tool, if available.
* **External Packages:** If a new feature requires an external package, use the
  `pub_dev_search` tool, if it is available. Otherwise, identify the most
  suitable and stable package from pub.dev.
* **Adding Dependencies:** To add a regular dependency, use the `pub` tool, if
  it is available. Otherwise, run `flutter pub add <package_name>`.
* **Adding Dev Dependencies:** To add a development dependency, use the `pub`
  tool, if it is available, with `dev:<package name>`. Otherwise, run `flutter
  pub add dev:<package_name>`.
* **Dependency Overrides:** To add a dependency override, use the `pub` tool, if
  it is available, with `override:<package name>:1.0.0`. Otherwise, run `flutter
  pub add override:<package_name>:1.0.0`.
* **Removing Dependencies:** To remove a dependency, use the `pub` tool, if it
  is available. Otherwise, run `dart pub remove <package_name>`.

## Code Quality
* **Code structure:** Adhere to maintainable code structure and separation of
  concerns (e.g., UI logic separate from business logic).
* **Naming conventions:** Avoid abbreviations and use meaningful, consistent,
  descriptive names for variables, functions, and classes.
* **Conciseness:** Write code that is as short as it can be while remaining
  clear.
* **Simplicity:** Write straightforward code. Code that is clever or
  obscure is difficult to maintain.
* **Error Handling:** Anticipate and handle potential errors. Don't let your
  code fail silently.
* **Styling:**
    * Line length: Lines should be 80 characters or fewer.
    * Use `PascalCase` for classes, `camelCase` for
      members/variables/functions/enums, and `snake_case` for files.
* **Functions:**
    * Functions short and with a single purpose (strive for less than 20 lines).
* **Testing:** Write code with testing in mind. Use the `file`, `process`, and
  `platform` packages, if appropriate, so you can inject in-memory and fake
  versions of the objects.
* **Logging:** Use the `logging` package instead of `print`.

## Dart Best Practices
* **Effective Dart:** Follow the official Effective Dart guidelines
  (https://dart.dev/effective-dart)
* **Class Organization:** Define related classes within the same library file.
  For large libraries, export smaller, private libraries from a single top-level
  library.
* **Library Organization:** Group related libraries in the same folder.
* **API Documentation:** Add documentation comments to all public APIs,
  including classes, constructors, methods, and top-level functions.
* **Comments:** Write clear comments for complex or non-obvious code. Avoid
  over-commenting.
* **Trailing Comments:** Don't add trailing comments.
* **Async/Await:** Ensure proper use of `async`/`await` for asynchronous
  operations with robust error handling.
    * Use `Future`s, `async`, and `await` for asynchronous operations.
    * Use `Stream`s for sequences of asynchronous events.
* **Null Safety:** Write code that is soundly null-safe. Leverage Dart's null
  safety features. Avoid `!` unless the value is guaranteed to be non-null.
* **Pattern Matching:** Use pattern matching features where they simplify the
  code.
* **Records:** Use records to return multiple types in situations where defining
  an entire class is cumbersome.
* **Switch Statements:** Prefer using exhaustive `switch` statements or
  expressions, which don't require `break` statements.
* **Exception Handling:** Use `try-catch` blocks for handling exceptions, and
  use exceptions appropriate for the type of exception. Use custom exceptions
  for situations specific to your code.
* **Arrow Functions:** Use arrow syntax for simple one-line functions.

## Flutter Best Practices
* **Immutability:** Widgets (especially `StatelessWidget`) are immutable; when
  the UI needs to change, Flutter rebuilds the widget tree.
* **Composition:** Prefer composing smaller widgets over extending existing
  ones. Use this to avoid deep widget nesting.
* **Private Widgets:** Use small, private `Widget` classes instead of private
  helper methods that return a `Widget`.
* **Build Methods:** Break down large `build()` methods into smaller, reusable
  private Widget classes.
* **List Performance:** Use `ListView.builder` or `SliverList` for long lists to
  create lazy-loaded lists for performance.
* **Isolates:** Use `compute()` to run expensive calculations in a separate
  isolate to avoid blocking the UI thread, such as JSON parsing.
* **Const Constructors:** Use `const` constructors for widgets and in `build()`
  methods whenever possible to reduce rebuilds.
* **Build Method Performance:** Avoid performing expensive operations, like
  network calls or complex computations, directly within `build()` methods.

## API Design Principles
When building reusable APIs, such as a library, follow these principles.

* **Consider the User:** Design APIs from the perspective of the person who will
  be using them. The API should be intuitive and easy to use correctly.
* **Documentation is Essential:** Good documentation is a part of good API
  design. It should be clear, concise, and provide examples.

## Application Architecture
* **Separation of Concerns:** Aim for separation of concerns similar to MVC/MVVM, with defined Model,
  View, and ViewModel/Controller roles.
* **Logical Layers:** Organize the project into logical layers:
    * Presentation (widgets, screens)
    * Domain (business logic classes)
    * Data (model classes, API clients)
    * Core (shared classes, utilities, and extension types)
* **Feature-based Organization:** For larger projects, organize code by feature,
  where each feature has its own presentation, domain, and data subfolders. This
  improves navigability and scalability.

## Lint Rules

Include the package in the `analysis_options.yaml` file. Use the following
analysis_options.yaml file as a starting point:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add additional lint rules here:
    # avoid_print: false
    # prefer_single_quotes: true
```

### State Management
* **Built-in Solutions:** Prefer Flutter's built-in state management solutions.
  Do not use a third-party package unless explicitly requested.
* **Streams:** Use `Streams` and `StreamBuilder` for handling a sequence of
  asynchronous events.
* **Futures:** Use `Futures` and `FutureBuilder` for handling a single
  asynchronous operation that will complete in the future.
* **ValueNotifier:** Use `ValueNotifier` with `ValueListenableBuilder` for
  simple, local state that involves a single value.

  ```dart
  // Define a ValueNotifier to hold the state.
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  // Use ValueListenableBuilder to listen and rebuild.
  ValueListenableBuilder<int>(
    valueListenable: _counter,
    builder: (context, value, child) {
      return Text('Count: $value');
    },
  );
    ```

* **ChangeNotifier:** For state that is more complex or shared across multiple
  widgets, use `ChangeNotifier`.
* **ListenableBuilder:** Use `ListenableBuilder` to listen to changes from a
  `ChangeNotifier` or other `Listenable`.
* **MVVM:** When a more robust solution is needed, structure the app using the
  Model-View-ViewModel (MVVM) pattern.
* **Dependency Injection:** Use simple manual constructor dependency injection
  to make a class's dependencies explicit in its API, and to manage dependencies
  between different layers of the application.
* **Provider:** If a dependency injection solution beyond manual constructor
  injection is explicitly requested, `provider` can be used to make services,
  repositories, or complex state objects available to the UI layer without tight
  coupling (note: this document generally defaults against third-party packages
  for state management unless explicitly requested).

### Data Flow
* **Data Structures:** Define data structures (classes) to represent the data
  used in the application.
* **Data Abstraction:** Abstract data sources (e.g., API calls, database
  operations) using Repositories/Services to promote testability.

### Routing
* **GoRouter:** Use the `go_router` package for declarative navigation, deep
  linking, and web support.
* **GoRouter Setup:** To use `go_router`, first add it to your `pubspec.yaml`
  using the `pub` tool's `add` command.

  ```dart
  // 1. Add the dependency
  // flutter pub add go_router

  // 2. Configure the router
  final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'details/:id', // Route with a path parameter
            builder: (context, state) {
              final String id = state.pathParameters['id']!;
              return DetailScreen(id: id);
            },
          ),
        ],
      ),
    ],
  );

  // 3. Use it in your MaterialApp
  MaterialApp.router(
    routerConfig: _router,
  );
  ```
* **Authentication Redirects:** Configure `go_router`'s `redirect` property to
  handle authentication flows, ensuring users are redirected to the login screen
  when unauthorized, and back to their intended destination after successful
  login.

* **Navigator:** Use the built-in `Navigator` for short-lived screens that do
  not need to be deep-linkable, such as dialogs or temporary views.

  ```dart
  // Push a new screen onto the stack
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const DetailsScreen()),
  );

  // Pop the current screen to go back
  Navigator.pop(context);
  ```

### Data Handling & Serialization
* **JSON Serialization:** Use `json_serial