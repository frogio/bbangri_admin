import 'package:flutter/material.dart';

class NoticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 실제로는 Supabase 연동해서 notice 리스트 표시!
    return Center(child: Text("공지 관리 페이지", style: TextStyle(fontSize: 28)));
  }
}
