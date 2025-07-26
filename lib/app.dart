import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login_page.dart';
import 'pages/admin_layout.dart';
import 'providers/auth_provider.dart';

class App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bbanggree',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFFD5A87F, {
          50: Color(0xFFF9F4F0),
          100: Color(0xFFF0E4D9),
          200: Color(0xFFE7D4C0),
          300: Color(0xFFDDC3A7),
          400: Color(0xFFD5B693),
          500: Color(0xFFD5A87F),
          600: Color(0xFFCEA077),
          700: Color(0xFFC6976C),
          800: Color(0xFFBE8D62),
          900: Color(0xFFB27D4F),
        }),
        scaffoldBackgroundColor: MaterialColor(0xFFFFF9F2, {
          50: Color(0xFFFFF9F2),
          100: Color(0xFFFFF4E6),
          200: Color(0xFFFFEEDB),
          300: Color(0xFFFFE8CF),
          400: Color(0xFFFFE2C4),
          500: Color(0xFFFFDCC8),
          600: Color(0xFFFFD6BC),
          700: Color(0xFFFFD0B1),
          800: Color(0xFFFFCBA5),
          900: Color(0xFFFFC59A),
        }),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFFD5A87F, {
            50: Color(0xFFF9F4F0),
            100: Color(0xFFF0E4D9),
            200: Color(0xFFE7D4C0),
            300: Color(0xFFDDC3A7),
            400: Color(0xFFD5B693),
            500: Color(0xFFD5A87F),
            600: Color(0xFFCEA077),
            700: Color(0xFFC6976C),
            800: Color(0xFFBE8D62),
            900: Color(0xFFB27D4F),
          }),
        ).copyWith(primary: Color(0xFFD5A87F), secondary: Color(0xFFFFF9F2)),
      ),
      home: isLoggedIn ? AdminLayout() : LoginPage(),
    );
  }
}
