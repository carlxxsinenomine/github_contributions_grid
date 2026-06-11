# github_contributions_grid

A Flutter package to display a GitHub-style contribution graph/grid based on a user's GitHub activity, using data from the `jogruber` contributions API.

## Features

- Fetches a user's GitHub contribution data for the last year.
- Renders a clean, responsive grid of contribution cells.
- Fully customizable colors, text styles, and layout sizing.
- Handles scaling to fit parent layouts nicely (scales cell sizes to fit both width and height).

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  github_contributions_grid: ^1.0.0
```

## Usage

Basic usage requires just the GitHub username:

```dart
import 'package:github_contributions_grid/github_contributions_grid.dart';
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      child: GitHubContributionsGrid(
        username: 'octocat',
      ),
    );
  }
}
```

### Advanced Usage with Customization

You can customize the color palette, fonts, and sizing parameters. For example, to make a red-themed grid:

```dart
GitHubContributionsGrid(
  username: 'your-username',
  levelColors: const [
    Color(0xFF1A1A1E), // Level 0: Empty
    Color(0xFF4B0C0C), // Level 1
    Color(0xFF7A1515), // Level 2
    Color(0xFFB22222), // Level 3
    Color(0xFFFF3333), // Level 4: Most active
  ],
  labelStyle: const TextStyle(
    color: Color(0xFF888888),
    fontFamily: 'Jetbrains Mono',
    fontSize: 10,
  ),
  cellRadius: 2.0,
  cellSpacing: 2.5,
  dayLabelWidth: 30.0,
  monthLabelHeight: 16.0,
)
```

## Additional information

This package uses the free [github-contributions-api.jogruber.de](https://github-contributions-api.jogruber.de) API to fetch contribution data without needing any authentication or CORS workarounds for Flutter Web.
