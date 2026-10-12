import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  // Garante que o Flutter está pronto antes de ligar à internet
  WidgetsFlutterBinding.ensureInitialized();
  
  // Liga o aplicativo ao seu servidor Supabase
  await Supabase.initialize(
    url: 'https://jncvvwqqugnkqznmbajm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpuY3Z2d3FxdWdua3F6bm1iYWptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NTk5NTQsImV4cCI6MjEwNzMzNTk1NH0.66FfH91G1hS-iIT2J4bGrGtvZz53Oj64ihAA_vx7EUI',
  );

  runApp(const CombustivelApp());
}

class CombustivelApp extends StatelessWidget {
  const CombustivelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combustível SP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
      ),
      home: LoginScreen(),
    );
  }
}
