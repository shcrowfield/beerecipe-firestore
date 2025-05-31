import 'package:beerecipe/sign_in_page.dart';
import 'package:beerecipe/style.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BeerRecipe());
}

class BeerRecipe extends StatelessWidget {
  const BeerRecipe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beer Recipe',
      theme: appTheme,
      routes:
      {
        '/': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

