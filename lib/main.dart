import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/providers/auth_provider.dart';
import 'package:ratting_test/providers/favorite_provider.dart';
import 'package:ratting_test/providers/movie_provider.dart';
import 'package:ratting_test/views/splash_view.dart';
import 'firebase_options.dart';

void main() async {
  // WAJIB: harus ada sebelum Firebase.initializeApp
  WidgetsFlutterBinding.ensureInitialized();

  // WAJIB: inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => MovieProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteProvider()),
    ],
    child: const MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rating App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}