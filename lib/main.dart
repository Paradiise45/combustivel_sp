import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/map_screen.dart';

// O nosso tema visual profissional inspirado no seu mockup
final _temaClaro = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E5B3E), // Verde escuro elegante
    primary: const Color(0xFF2E5B3E),
    secondary: Colors.amber,
    surface: const Color(0xFFF7F9F8), // Fundo quase branco
    onSurface: const Color(0xFF1E1E1E), // Texto escuro
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1E1E1E),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E5B3E),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

// PONTO DE ENTRADA DO APLICATIVO
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://jncvvwqqugnkqznmbajm.supabase.co', // <--- COLOQUE A SUA URL AQUI
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpuY3Z2d3FxdWdua3F6bm1iYWptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NTk5NTQsImV4cCI6MjEwNzMzNTk1NH0.66FfH91G1hS-iIT2J4bGrGtvZz53Oj64ihAA_vx7EUI', // <--- COLOQUE A SUA CHAVE AQUI
  );

  runApp(const ProviderScope(child: CombustivelApp()));
}

// O ROUTER (Gestor de Navegação)
final _router = GoRouter(
  initialLocation: '/',
  // Redirecionamento de segurança: se não estiver logado, obriga a ir para o Login
  redirect: (context, state) {
    final sessao = Supabase.instance.client.auth.currentSession;
    final isLoginRoute = state.uri.path == '/login' || state.uri.path == '/cadastro';
    
    if (sessao == null && !isLoginRoute) {
      return '/login';
    }
    if (sessao != null && isLoginRoute) {
      return '/'; // Vai para o mapa
    }
    return null; // Deixa o utilizador prosseguir
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(), 
    ),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => CadastroScreen(), 
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => MapaScreen(), 
    ),
  ],
);

class CombustivelApp extends StatelessWidget {
  const CombustivelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Combustível SP',
      debugShowCheckedModeBanner: false,
      theme: _temaClaro,       
      themeMode: ThemeMode.light, 
      routerConfig: _router,
    );
  }
}
