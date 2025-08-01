import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InquiryPage extends StatefulWidget {
  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  late Future<List<Map<String, dynamic>>> _futureQnas;

  String _searchKeyword = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureQnas = fetchQnas();
  }

Future<List<Map<String, dynamic>>> fetchQnas() async {
    final data = await Supabase.instance.client
        .from('qnas')
        .select(
          'qna_id, qna_name, date, qna_detail, qna_answer, profiles (name)',
        )
        .order('qna_id', ascending: false);
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

  void _showAnswerDialog(Map<String, dynamic> qna, Map<String, dynamic> profile) {
    final title = qna['qna_name'] ?? '';
    final author = profile['name'] ?? '알 수 없음';
    final detail = qna['qna_detail'] ?? '';
    final date = qna['date'];
    final answerController = TextEditingController(
      text: qna['qna_answer'] ?? '',
    );
    final isAnswered = (qna['qna_answer'] ?? '').toString().trim().isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8, // 화면 80% 한계
              minWidth: 400,
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '작성자: $author',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '작성일: ${formatDate(date)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '문의 내용',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: 120, // 원하는 최대 높이 (예: 120)
                        minWidth: 300,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Text(
                          detail,
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      controller: answerController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: '답변 내용',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final answer = answerController.text.trim();
                        if (answer.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('답변 내용을 입력해주세요.')),
                          );
                          return;
                        }
                        try {
                          await Supabase.instance.client
                              .from('qnas')
                              .update({'qna_answer': answer})
                              .eq('qna_id', qna['qna_id']);
                          setState(() {
                            _futureQnas = fetchQnas();
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('답변이 저장되었습니다.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('저장 실패: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD5A87F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isAnswered ? '수정하기' : '저장하기',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '문의 내역',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색 (이름 또는 문의 제목을 입력해주세요.)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                ]
              ),
            ],
          ),
          SizedBox(height: 28),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureQnas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 불러오기 오류: ${snapshot.error}'));
                }
                final qnas = snapshot.data ?? [];
                final filteredQnas = _searchKeyword.isEmpty
                    ? qnas
                    : qnas.where((qna) {
                        final title = (qna['qna_name'] ?? '').toString().toLowerCase();
                        final author = ((qna['profiles'] ?? {})['name'] ?? '').toString().toLowerCase();
                        return title.contains(_searchKeyword.toLowerCase()) ||
                              author.contains(_searchKeyword.toLowerCase());
                      }).toList();

                // 페이지네이션 로직
                final total = filteredQnas.length;
                final totalPages = (total / _rowsPerPage).ceil().clamp(1, 999);
                final startIdx = (_currentPage - 1) * _rowsPerPage;
                final endIdx = (startIdx + _rowsPerPage).clamp(0, total);
                final visibleQnas = filteredQnas.sublist(
                  startIdx,
                  endIdx,
                );

                if (visibleQnas.isEmpty) {
                  return Center(child: Text('문의 내역이 없습니다.'));
                }

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
                                  columnSpacing: 32,
                                  columns: [
                                    DataColumn(label: Text('No')),
                                    DataColumn(label: Text('작성자')),
                                    DataColumn(label: Text('문의 제목')),
                                    DataColumn(label: Text('작성일')),
                                    DataColumn(label: Text('답변 상태')),
                                  ],
                                  rows: visibleQnas.map((qna) {
                                    final profile = qna['profiles'] ?? {};
                                    final answer = qna['qna_answer'] ?? '';
                                    final isAnswered = answer.trim().isNotEmpty;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(qna['qna_id'].toString())),
                                        DataCell(Text(profile['name'] ?? '')),
                                        DataCell(Text(qna['qna_name'] ?? '')),
                                        DataCell(Text(formatDate(qna['date']))),
                                        DataCell(
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isAnswered
                                                  ? Colors.grey[300]
                                                  : Colors.white, // 배경색
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1,
                                              ),
                                            ),
                                            child: OutlinedButton(
                                              onPressed: () => _showAnswerDialog(qna, profile),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent, // 투명 처리
                                                foregroundColor: Colors.black,
                                                minimumSize: Size(
                                                  80,
                                                  38,
                                                ), // 사이즈는 필요에 따라 조절
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 0,
                                                ),
                                                side: BorderSide
                                                    .none, // border는 Container에서 처리
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                isAnswered ? '답변완료' : '답변미완료',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
                  ]
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
