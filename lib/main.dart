import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '빵그리',
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
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final inputId = _idController.text.trim();
      final inputPw = _passwordController.text.trim();

      try {
        final data = await Supabase.instance.client
            .from('admin_info')
            .select()
            .eq('id', inputId)
            .eq('pw', inputPw)
            .maybeSingle();

        if (data != null) {
          // Login successful
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('로그인 성공!')));
        } else {
          // Login failed
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('아이디 또는 비밀번호가 일치하지 않습니다.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 중 오류 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo or app name
              Image.network(
                'icons/Icon-w-name-512.png',
                width: screenWidth / 5,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 48),

              // Login form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ID field
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _idController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '아이디를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password field
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD5A87F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text('로그인', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
