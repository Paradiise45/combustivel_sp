import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart'; // Importa a tela do mapa

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'COLE_AQUI_A_SUA_URL', // <--- COLOQUE A SUA URL AQUI
    anonKey: 'COLE_AQUI_A_SUA_CHAVE_ANON', // <--- COLOQUE A SUA CHAVE AQUI
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
      // O app agora arranca na tela de verificação
      home: SplashSessaoScreen(),
    );
  }
}

// === TELA DE VERIFICAÇÃO DE SESSÃO ===
class SplashSessaoScreen extends StatefulWidget {
  @override
  _SplashSessaoScreenState createState() => _SplashSessaoScreenState();
}

class _SplashSessaoScreenState extends State<SplashSessaoScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    // Dá um tempinho minúsculo para a tela renderizar e a verificação acontecer
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Pergunta ao Supabase se há uma sessão ativa
    final sessao = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (sessao != null) {
      // Se houver sessão, vai direto pro mapa (sem opção de voltar pro login pelo botão voltar do celular)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MapaScreen()),
      );
    } else {
      // Se não houver, vai para a tela de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      body: Center(
        // Enquanto pensa, mostra um carregamento com a cor do app
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}
