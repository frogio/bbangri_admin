import 'package:flutter/material.dart';
import 'user_page.dart';
import 'post_page.dart';
import 'report_page.dart';
import 'inquiry_page.dart';
import 'settlement_page.dart';
import 'notice_page.dart';
import 'setting_page.dart';

class AdminLayout extends StatefulWidget {
  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedMenu = 0;

  final List<String> _menuItems = [
    'user',
    'post',
    'report',
    'inquiry',
    'settlement',
    'notice',
    'setting',
  ];

  Widget _getPage(int idx) {
    switch (idx) {
      case 0:
        return UserPage();
      case 1:
        return PostPage();
      case 2:
        return ReportPage();
      case 3:
        return InquiryPage();
      case 4:
        return SettlementPage();
      case 5:
        return NoticePage();
      case 6:
        return SettingPage();
      default:
        return UserPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드 메뉴
          Container(
            width: 220,
            color: Color(0xFFD5A87F),
            child: Column(
              children: [
                SizedBox(height: 36),
                Image.network('icons/Icon-w-name-512.png', width: 90),
                SizedBox(height: 16),
                ..._menuItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String label = _getMenuLabel(label: entry.value);
                  bool isSelected = _selectedMenu == idx;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMenu = idx;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? Color(0xFFD5A87F)
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // 우측 페이지
          Expanded(child: _getPage(_selectedMenu)),
        ],
      ),
    );
  }

  String _getMenuLabel({required String label}) {
    switch (label) {
      case 'user':
        return '사용자 관리';
      case 'post':
        return '게시글 관리';
      case 'report':
        return '신고 관리';
      case 'inquiry':
        return '문의 관리';
      case 'settlement':
        return '정산';
      case 'notice':
        return '공지';
      case 'setting':
        return '설정';
      default:
        return label;
    }
  }
}
