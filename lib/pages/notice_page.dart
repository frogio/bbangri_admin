import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'notice_edit_page.dart';

class NoticePage extends StatefulWidget {
  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  late Future<List<Map<String, dynamic>>> _futureNotices;
  int _rowsPerPage = 10;
  int _currentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureNotices = fetchNotices();
  }

  Future<List<Map<String, dynamic>>> fetchNotices() async {
    final data = await Supabase.instance.client
        .from('notification')
        .select('notification_id, notification_name, notification_date')
        .order('notification_id', ascending: false);
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

  void _showDeleteDialog(int noticeId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '삭제하시겠습니까?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await Supabase.instance.client
                            .from('notification')
                            .delete()
                            .eq('notification_id', noticeId);
                        setState(() {
                          _futureNotices = fetchNotices();
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                      }
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
    );
  }

  // 밀리초 타임스탬프 → yyyy.MM.dd 형태로 변환
  String formatDate(dynamic msTimestamp) {
    if (msTimestamp == null) return '';
    try {
      final millis = msTimestamp is int
          ? msTimestamp
          : int.tryParse(msTimestamp.toString()) ?? 0;
      if (millis == 0) return '';
      final date = DateTime.fromMillisecondsSinceEpoch(millis);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (_) {
      return '';
    }
  }

  void _goToEditNotice(BuildContext context, Map<String, dynamic> notice) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NoticeEditPage(notificationId: notice['notification_id'])));
  }

  void _showAddNoticeDialog() {
    final _titleController = TextEditingController();
    final _detailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  '공지사항 작성',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '공지 제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _detailController,
                  decoration: InputDecoration(
                    labelText: '공지 내용',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 6,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      final detail = _detailController.text.trim();
                      if (title.isEmpty || detail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('제목과 내용을 입력하세요.')),
                        );
                        return;
                      }
                      try {
                        await Supabase.instance.client
                            .from('notification')
                            .insert({
                              'notification_name': title,
                              'notification_detail': detail,
                              'notification_date':
                                  DateTime.now().millisecondsSinceEpoch,
                            });
                        setState(() {
                          _futureNotices = fetchNotices();
                        });
                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD5A87F),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('저장하기'),
                  ),
                ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '공지',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
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
                  SizedBox(width: 16), // ← 원하는 만큼 간격
                  ElevatedButton(
                    onPressed: _showAddNoticeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text('추가하기', style: TextStyle(fontSize: 16)),
                  )
                ]
              ),
            ],
          ),
          SizedBox(height: 28),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureNotices,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 불러오기 오류: ${snapshot.error}'));
                }
                final notices = snapshot.data ?? [];
                if (notices.isEmpty) {
                  return Center(child: Text('등록된 공지사항이 없습니다.'));
                }

                // 페이지네이션 로직
                final total = notices.length;
                final totalPages = (total / _rowsPerPage).ceil().clamp(1, 999);
                final startIdx = (_currentPage - 1) * _rowsPerPage;
                final endIdx = (startIdx + _rowsPerPage).clamp(0, total);
                final visibleNotices = notices.sublist(startIdx, endIdx);

                return Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columnSpacing: 24,
                                  columns: [
                                    DataColumn(label: Text('No')),
                                    DataColumn(label: Text('공지 제목')),
                                    DataColumn(label: Text('작성일')),
                                    DataColumn(label: Text('삭제')),
                                  ],
                                  rows: visibleNotices.map((notice) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(notice['notification_id'].toString()),
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) => NoticeEditPage(
                                                      notificationId:
                                                          notice['notification_id'],
                                                    ),
                                                  ),
                                                )
                                                .then((result) {
                                                  // result == true면 수정 성공, 새로고침 등 처리 가능
                                                });
                                          }
                                        ),
                                        DataCell(
                                          Text(notice['notification_name'] ?? ''),
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) => NoticeEditPage(
                                                      notificationId:
                                                          notice['notification_id'],
                                                    ),
                                                  ),
                                                )
                                                .then((result) {
                                                  // result == true면 수정 성공, 새로고침 등 처리 가능
                                                });
                                          }
                                        ),
                                        DataCell(
                                          Text(
                                            formatDate(notice['notification_date']),
                                          ),
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder: (_) => NoticeEditPage(
                                                      notificationId:
                                                          notice['notification_id'],
                                                    ),
                                                  ),
                                                )
                                                .then((result) {
                                                  // result == true면 수정 성공, 새로고침 등 처리 가능
                                                });
                                          }
                                        ),
                                        DataCell(
                                          ElevatedButton(
                                            onPressed: () {
                                              _showDeleteDialog(
                                                notice['notification_id'],
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey[300],
                                              foregroundColor: Colors.black,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  5,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '삭제하기',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
