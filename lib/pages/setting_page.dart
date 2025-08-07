import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert'; // for utf8
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class SettingPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  final _pwController = TextEditingController();
  final _pwController2 = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddrController = TextEditingController();
  final _companyRegNumController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;
  String? _termsText;
  String? _privacyText;

  @override
  void dispose() {
    _pwController.dispose();
    _pwController2.dispose();
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyAddrController.dispose();
    _companyRegNumController.dispose();
    super.dispose();
  }

  void _saveInfo() async {
    final adminId = ref.read(adminIdProvider);
    if (adminId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('관리자 정보가 없습니다. 로그인을 다시 해주세요.')));
      return;
    }

    final pw1 = _pwController.text.trim();
    final pw2 = _pwController2.text.trim();
    final companyName = _companyNameController.text.trim();
    final companyPhone = _companyPhoneController.text.trim();
    final companyAddr = _companyAddrController.text.trim();
    final companyRegNum = _companyRegNumController.text.trim();

    final isPw1Filled = pw1.isNotEmpty;
    final isPw2Filled = pw2.isNotEmpty;

    if (!isPw1Filled && !isPw2Filled) {
      // 비밀번호란 비워져 있을 때: 회사정보만 업데이트
      await Supabase.instance.client
          .from('admin_info')
          .update({
            'company_name': companyName,
            'cellphone': companyPhone,
            'address': companyAddr,
            'company_no': companyRegNum,
          })
          .eq('admin_id', adminId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회사 정보가 성공적으로 변경되었습니다!')));
    } else if (isPw1Filled != isPw2Filled) {
      // 둘 중 하나만 입력
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('두 비밀번호 입력란 모두 입력해주세요.')));
    } else if (pw1 != pw2) {
      // 비밀번호 다름
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('두 비밀번호 입력 내용이 동일하지 않습니다.')));
    } else {
      // 비밀번호 입력란이 동일하면 전체 업데이트
      await Supabase.instance.client
          .from('admin_info')
          .update({
            'pw': pw1,
            'company_name': companyName,
            'cellphone': companyPhone,
            'address': companyAddr,
            'company_no': companyRegNum,
          })
          .eq('admin_id', adminId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('비밀번호 및 회사 정보가 성공적으로 변경되었습니다!')));
    }
  }

  Future<String> fetchTermsWebFile({required String file}) async {
    final url = Uri.base.resolve(file).toString();
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('약관 파일을 불러올 수 없습니다.');
    }
  }

  Future<void> _showTermsDialog({required bool isTerms}) async {
    if (isTerms && _termsText == null) {
      try {
        _termsText = await fetchTermsWebFile(file: 'terms_of_service.txt');
      } catch (e) {
        _termsText = '약관을 불러오지 못했습니다.\n$e';
      }
    } else if (!isTerms && _privacyText == null) {
      try {
        _privacyText = await fetchTermsWebFile(file: 'privacy_policy.txt');
      } catch (e) {
        _privacyText = '개인정보 처리방침을 불러오지 못했습니다.\n$e';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              minWidth: 280,
              maxHeight: 520,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 닫기버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isTerms ? '서비스 이용약관' : '개인정보 처리방침',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.centerLeft, // ← 여기!
                          child: Text(
                            isTerms ? _termsText ?? '' : _privacyText ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 28),
                    Text(
                      '관리자 정보 변경',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    TextFormField(
                      controller: _pwController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: '비밀번호 재설정',
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
                          return '비밀번호 재설정란에 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _pwController2,
                      obscureText: !_isPasswordVisible2,
                      decoration: InputDecoration(
                        labelText: '비밀번호 재입력',
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
                          return '비밀번호 재입력란에 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 28),
                    Text(
                      '회사 정보 변경',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        labelText: '회사명',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '회사명을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _companyPhoneController,
                      decoration: InputDecoration(
                        labelText: '대표전화',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '대표전화를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _companyAddrController,
                      decoration: InputDecoration(
                        labelText: '주소',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '주소를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _companyRegNumController,
                      decoration: InputDecoration(
                        labelText: '사업자등록번호',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '사업자등록번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD5A87F),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text('저장하기', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(height: 28),
                    Text(
                      '약관 및 방침',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '서비스 이용약관',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showTermsDialog(isTerms: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFD5A87F),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 18,
                                ),
                                textStyle: TextStyle(fontSize: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0, // flat style
                              ),
                              child: Text('자세히 보기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '개인정보 처리방침',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showTermsDialog(isTerms: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFD5A87F),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 18,
                                ),
                                textStyle: TextStyle(fontSize: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0, // flat style
                              ),
                              child: Text('자세히 보기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    Text(
                      '앱 정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '현재 버전: 1.0.0',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
