

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Data model for a single day's contribution
class Contribution {
  final DateTime date;
  final int count;
  final int level; // 0-4

  const Contribution({
    required this.date,
    required this.count,
    required this.level,
  });
}

/// A widget that displays a GitHub-style contribution grid
class GitHubContributionsGrid extends StatefulWidget {
  /// The GitHub username to fetch contributions for
  final String username;

  /// Custom color palette for contribution levels (must contain exactly 5 colors)
  /// Defaults to a standard GitHub green palette.
  final List<Color>? levelColors;

  /// Text style for month and day labels
  final TextStyle? labelStyle;

  /// Text style for error messages
  final TextStyle? errorStyle;

  /// Widget to show while loading data
  final Widget? loadingIndicator;

  /// Corner radius for the contribution cells
  final double cellRadius;

  /// Spacing between the contribution cells
  final double cellSpacing;

  /// Width reserved for the day labels (Mon, Wed, Fri) on the left
  final double dayLabelWidth;

  /// Height reserved for the month labels on the top
  final double monthLabelHeight;

  /// Padding at the bottom of the grid
  final double bottomPadding;

  const GitHubContributionsGrid({
    super.key,
    required this.username,
    this.levelColors,
    this.labelStyle,
    this.errorStyle,
    this.loadingIndicator,
    this.cellRadius = 2.0,
    this.cellSpacing = 2.5,
    this.dayLabelWidth = 30.0,
    this.monthLabelHeight = 16.0,
    this.bottomPadding = 4.0,
  }) : assert(levelColors == null || levelColors.length == 5,
            'levelColors must contain exactly 5 colors');

  @override
  State<GitHubContributionsGrid> createState() =>
      _GitHubContributionsGridState();
}

class _GitHubContributionsGridState extends State<GitHubContributionsGrid> {
  List<Contribution>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(
        'https://github-contributions-api.jogruber.de/v4/${widget.username}?y=last',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['contributions'] as List).cast<Map<String, dynamic>>();

      final contributions = list.map((e) {
        return Contribution(
          date: DateTime.parse(e['date'] as String),
          count: (e['count'] as num).toInt(),
          level: (e['level'] as num).toInt(),
        );
      }).toList();

      if (mounted) setState(() => _data = contributions);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Could not load contributions',
          style: widget.errorStyle ??
              TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
        ),
      );
    }

    if (_data == null) {
      return Center(
        child: widget.loadingIndicator ??
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
              ),
            ),
      );
    }

    final defaultColors = [
      const Color(0xFFEBEDF0),
      const Color(0xFF9BE9A8),
      const Color(0xFF40C463),
      const Color(0xFF30A14E),
      const Color(0xFF216E39),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 160.0;
        return SizedBox(
          width: w,
          height: h,
          child: ClipRect(
            child: CustomPaint(
              size: Size(w, h),
              painter: _ContributionPainter(
                contributions: _data!,
                levelColors: widget.levelColors ?? defaultColors,
                labelStyle: widget.labelStyle ??
                    const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 10,
                    ),
                cellRadius: widget.cellRadius,
                cellSpacing: widget.cellSpacing,
                dayLabelWidth: widget.dayLabelWidth,
                monthLabelHeight: widget.monthLabelHeight,
                bottomPadding: widget.bottomPadding,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContributionPainter extends CustomPainter {
  final List<Contribution> contributions;
  final List<Color> levelColors;
  final TextStyle labelStyle;
  final double cellRadius;
  final double cellSpacing;
  final double dayLabelWidth;
  final double monthLabelHeight;
  final double bottomPadding;

  const _ContributionPainter({
    required this.contributions,
    required this.levelColors,
    required this.labelStyle,
    required this.cellRadius,
    required this.cellSpacing,
    required this.dayLabelWidth,
    required this.monthLabelHeight,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (contributions.isEmpty) return;

    const int rows = 7;

    // Build week grid: weekIdx → dowIdx → contribution
    final Map<int, Map<int, Contribution>> grid = {};
    for (final c in contributions) {
      final int dow = c.date.weekday % 7; // Sun=0 … Sat=6
      final int weekIdx = _weekIndexOf(c.date, contributions.first.date);
      grid.putIfAbsent(weekIdx, () => {})[dow] = c;
    }

    final int totalWeeks =
        grid.keys.isEmpty ? 0 : grid.keys.reduce((a, b) => a > b ? a : b) + 1;
    if (totalWeeks == 0) return;

    // Cell size: fit both axes, take the smaller 
    final double availW = size.width - dayLabelWidth;
    final double availH = size.height - monthLabelHeight - bottomPadding;

    final double cellFromH = (availH - (rows - 1) * cellSpacing) / rows;
    final double cellFromW = (availW - (totalWeeks - 1) * cellSpacing) / totalWeeks;
    final double cell = cellFromH < cellFromW ? cellFromH : cellFromW;

    final double colW = cell + cellSpacing;

    // Calculate centering offset 
    final double drawnWidth = dayLabelWidth + totalWeeks * colW - cellSpacing;
    final double offsetX = drawnWidth < size.width ? (size.width - drawnWidth) / 2 : 0.0;

    final double drawnHeight = monthLabelHeight + (rows * cell) + ((rows - 1) * cellSpacing);
    final double offsetY = drawnHeight < size.height ? (size.height - drawnHeight) / 2 : 0.0;

    // Clip canvas so nothing overflows 
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Month labels 
    final tp = TextPainter(textDirection: TextDirection.ltr);
    String? lastMonth;
    for (int w = 0; w < totalWeeks; w++) {
      final weekData = grid[w];
      if (weekData == null) continue;
      final firstDay =
          weekData.values.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      final monthName = _monthAbbr(firstDay.date.month);
      if (monthName != lastMonth) {
        lastMonth = monthName;
        tp.text = TextSpan(text: monthName, style: labelStyle);
        tp.layout();
        final dx = offsetX + dayLabelWidth + w * colW;
        if (dx + tp.width <= size.width) {
          tp.paint(canvas, Offset(dx, offsetY));
        }
      }
    }

    // Day labels (Mon / Wed / Fri) 
    for (final entry in {1: 'Mon', 3: 'Wed', 5: 'Fri'}.entries) {
      tp.text = TextSpan(text: entry.value, style: labelStyle);
      tp.layout();
      final dy = offsetY + monthLabelHeight +
          entry.key * (cell + cellSpacing) +
          (cell - tp.height) / 2;
      tp.paint(canvas, Offset(offsetX, dy));
    }

    // Contribution cells 
    final paint = Paint()..style = PaintingStyle.fill;
    
    // allow cellRadius override but default to dynamic sizing logic if not specified
    // actually, let's just use what's given, default is 2.0
    // In original code it clamped (cell * 0.15) between 1 and 3. Let's do that if cellRadius < 0, else use cellRadius
    final double radius = cellRadius < 0 ? (cell * 0.15).clamp(1.0, 3.0) : cellRadius;

    for (int w = 0; w < totalWeeks; w++) {
      final weekData = grid[w] ?? {};
      for (int d = 0; d < rows; d++) {
        final contrib = weekData[d];
        final level = contrib?.level ?? 0;
        paint.color = levelColors[level.clamp(0, 4)];

        final left = offsetX + dayLabelWidth + w * colW;
        final top = offsetY + monthLabelHeight + d * (cell + cellSpacing);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cell, cell),
            Radius.circular(radius),
          ),
          paint,
        );
      }
    }
  }

  static int _weekIndexOf(DateTime date, DateTime first) {
    final int startOffset = first.weekday % 7;
    final int daysSinceFirst = date.difference(first).inDays;
    return (daysSinceFirst + startOffset) ~/ 7;
  }

  static String _monthAbbr(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  @override
  bool shouldRepaint(_ContributionPainter old) =>
      old.contributions != contributions ||
      old.levelColors != levelColors ||
      old.labelStyle != labelStyle;
}
