import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:flutter_ecosed/flutter_ecosed.dart';
import 'package:termplux/main_tiny.dart';

import 'binding.dart';
import 'observer.dart';

void main() {
  PageVisibilityBinding.instance
      .addGlobalObserver(AppGlobalPageVisibilityObserver());
  CustomFlutterBinding();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String appName = "TermPlux-App";

  static Map<String, FlutterBoostRouteFactory> routerMap = {
    '/': (settings, uniqueId) {
      return MaterialPageRoute(
          settings: settings,
          builder: (_) {
            return const MyTinyApp();
          });
    },
    '/manager': (settings, uniqueId) {
      return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            return EcosedApp(
              materialHome: (body, exec) => body,
              bannerLocation: BannerLocation.topStart,
              appName: appName,
              plugins: [],
            );
          });
    }
  };

  Route<dynamic>? routeFactory(RouteSettings settings, String? uniqueId) {
    FlutterBoostRouteFactory? func = routerMap[settings.name!];
    if (func == null) return null;
    return func(settings, uniqueId);
  }

  Widget appBuilder(BuildContext context, Widget home) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: home,
      builder: (context, child) => home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterBoostApp(
      routeFactory,
      appBuilder: (home) => appBuilder(
        context,
        home,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Manager extends StatefulWidget {
  const Manager(
      {super.key, required this.body, required this.exec, required this.home});

  final Widget body;
  final EcosedExec exec;
  final Widget home;

  @override
  State<Manager> createState() => _ManagerState();
}

class _ManagerState extends State<Manager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TermPlux Manager'),
        centerTitle: true,
      ),
      body: widget.body,
    );
  }
}
