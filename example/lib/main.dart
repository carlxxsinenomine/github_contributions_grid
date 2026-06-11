import 'package:flutter/material.dart';
import 'package:github_contributions_grid/github_contributions_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Contributions Grid Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions Grid Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Default Green Theme:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16.0),
              child: const GitHubContributionsGrid(
                username: 'torvalds',
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Custom Red Theme:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF111111),
              child: GitHubContributionsGrid(
                username: 'torvalds',
                levelColors: const [
                  Color(0xFF1A1A1E),
                  Color(0xFF4B0C0C),
                  Color(0xFF7A1515),
                  Color(0xFFB22222),
                  Color(0xFFFF3333),
                ],
                labelStyle: const TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
