import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_layout.dart';
import '../providers/auth_provider.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwController2 = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwController2.dispose();
    super.dispose();
  }

  void _resetPasswordAndLogin() async {
    if (_formKey.currentState!.validate()) {
      final id = _idController.text.trim();
      final pw1 = _pwController.text.trim();
      final pw2 = _pwController2.text.trim();

      if (pw1 != pw2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
        return;
      }

      try {
        // 해당 id로 관리자 정보 찾기
        final data = await Supabase.instance.client
            .from('admin_info')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (data == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('존재하지 않는 아이디입니다.')));
          return;
        }

        // 비밀번호 업데이트
        await Supabase.instance.client
            .from('admin_info')
            .update({'pw': pw1})
            .eq('id', id);

        // 로그인 상태 업데이트 (authProvider, adminIdProvider)
        ref.read(authProvider.notifier).state = true;
        ref.read(adminIdProvider.notifier).state = data['admin_id'] as int;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('비밀번호 변경 및 로그인 성공!')));

        // 이동: 예를 들어 AdminLayout()로!
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => AdminLayout()));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('비밀번호 변경 오류: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '비밀번호 재설정',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 36),
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _idController,
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
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _pwController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '재설정 비밀번호',
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
                      if (value.length < 4) {
                        return '비밀번호는 4자 이상 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _pwController2,
                    obscureText: !_isPasswordVisible2,
                    decoration: InputDecoration(
                      labelText: '재설정 비밀번호 재입력',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible2
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible2 = !_isPasswordVisible2;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호 재입력을 입력해주세요.';
                      }
                      if (value.length < 4) {
                        return '비밀번호는 4자 이상 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: _resetPasswordAndLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD5A87F),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      '비밀번호 변경 및 로그인',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
