import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPage extends StatefulWidget {
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<List<Map<String, dynamic>>> _futureUsers;
  String _searchKeyword = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureUsers = fetchUsers();
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('user_id, name, cellphone, suspension_status, block_status')
        .order('user_id');
    return List<Map<String, dynamic>>.from(data);
  }

  void _onRowsPerPageChanged(int? value) {
    if (value == null) return;
    setState(() {
      _rowsPerPage = value;
      _currentPage = 1; // 개수 바꾸면 1페이지로
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _updateUserStatus({
    required int userId,
    required String field,
    required bool value,
  }) async {
    await Supabase.instance.client
        .from('profiles')
        .update({field: value})
        .eq('user_id', userId);
    // 데이터 갱신
    setState(() {
      _futureUsers = fetchUsers();
    });
  }

  Future<void> _showConfirmDialog({
    required String message,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(minWidth: 260, maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 24,
                    right: 24,
                    bottom: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close),
                            splashRadius: 18,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD5A87F),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('확인'),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onSwitchChange({
    required int userId,
    required String field,
    required bool prevValue,
  }) {
    if (!prevValue) {
      // 0 -> 1 : 팝업 띄우고 확정 시 true로 변경
      String msg = field == 'suspension_status'
          ? '계정 정지 하시겠습니까?'
          : '계정 차단 하시겠습니까?';
      _showConfirmDialog(
        message: msg,
        onConfirm: () async {
          await _updateUserStatus(userId: userId, field: field, value: true);
        },
      );
    } else {
      // 1 -> 0 : 즉시 변경
      _updateUserStatus(userId: userId, field: field, value: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 + 검색 + 개수 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '사용자 관리',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '이름 또는 휴대폰 번호 검색',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchKeyword = value.trim();
                          _currentPage = 1; // 검색할 때 1페이지로
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _rowsPerPage,
                    items: _rowsPerPageOptions
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text('$count개씩'),
                          ),
                        )
                        .toList(),
                    onChanged: _onRowsPerPageChanged,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 28),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 불러오기 오류: ${snapshot.error}'));
                }
                final users = snapshot.data ?? [];
                final filteredUsers = _searchKeyword.isEmpty
                    ? users
                    : users.where((user) {
                        final name = (user['name'] ?? '').toString();
                        final phone = (user['cellphone'] ?? '').toString();
                        return name.contains(_searchKeyword) ||
                            phone.contains(_searchKeyword);
                      }).toList();

                // 페이지네이션 로직
                final total = filteredUsers.length;
                final totalPages = (total / _rowsPerPage).ceil().clamp(1, 999);
                final startIdx = (_currentPage - 1) * _rowsPerPage;
                final endIdx = (startIdx + _rowsPerPage).clamp(0, total);
                final visibleUsers = filteredUsers.sublist(startIdx, endIdx);

                if (visibleUsers.isEmpty) {
                  return Center(child: Text('사용자 데이터가 없습니다.'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    columnSpacing: 32,
                                    columns: [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('이름')),
                                      DataColumn(label: Text('번호')),
                                      DataColumn(label: Text('계정 정지 여부')),
                                      DataColumn(label: Text('계정 차단 여부')),
                                    ],
                                    rows: visibleUsers.map((user) {
                                      final int userId = user['user_id'] as int;
                                      final bool suspension =
                                          user['suspension_status'] ?? false;
                                      final bool block =
                                          user['block_status'] ?? false;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(userId.toString())),
                                          DataCell(Text(user['name'] ?? '')),
                                          DataCell(Text(user['cellphone'] ?? '')),
                                          DataCell(
                                            Switch(
                                              value: suspension,
                                              onChanged: (_) {
                                                _onSwitchChange(
                                                  userId: userId,
                                                  field: 'suspension_status',
                                                  prevValue: suspension,
                                                );
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: block,
                                              onChanged: (_) {
                                                _onSwitchChange(
                                                  userId: userId,
                                                  field: 'block_status',
                                                  prevValue: block,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // 페이지네이션 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1
                              ? () => _onPageChanged(_currentPage - 1)
                              : null,
                        ),
                        for (int i = 1; i <= totalPages; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: OutlinedButton(
                              onPressed: _currentPage == i
                                  ? null
                                  : () => _onPageChanged(i),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _currentPage == i
                                    ? Color(0xFFD5A87F).withOpacity(0.12)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: _currentPage == i
                                      ? Color(0xFFD5A87F)
                                      : Colors.grey.shade400,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                              ),
                              child: Text(
                                '$i',
                                style: TextStyle(
                                  color: _currentPage == i
                                      ? Color(0xFFD5A87F)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: _currentPage < totalPages
                              ? () => _onPageChanged(_currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
