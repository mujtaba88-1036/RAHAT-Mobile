import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/crisis_provider.dart';
import 'screens/home_screen.dart';
import 'screens/input_screen.dart';
import 'screens/agent_trace_screen.dart';
import 'screens/outcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RahatApp());
}

class RahatApp extends StatelessWidget {
  const RahatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CrisisProvider()),
      ],
      child: MaterialApp(
        title: 'RAHAT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/':
              page = const HomeScreen();
              break;
            case '/input':
              page = const InputScreen();
              break;
            case '/trace':
              page = const AgentTraceScreen();
              break;
            case '/outcome':
              page = const OutcomeScreen();
              break;
            default:
              page = const HomeScreen();
          }

          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => page,
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
