import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'pages/home/home_page.dart';
=======
import 'firebase_options.dart';
import 'pages/events/events_list_page.dart';
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
import 'pages/auth/login_page.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
<<<<<<< HEAD
  await initializeDateFormatting('es_ES');
=======
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPN 360',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

<<<<<<< HEAD
        return const HomePage();
=======
        return EventsListPage();
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
      },
    );
  }
}
