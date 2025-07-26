import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 실제로는 Supabase 연동해서 user 리스트 표시!
    return Center(child: Text("사용자 관리 페이지", style: TextStyle(fontSize: 28)));
  }
}
