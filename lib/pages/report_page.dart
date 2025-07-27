import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPage extends StatefulWidget {
  @override
  State<ReportPage> createState() => _ReportPageState();
}

enum ReportTab { reason, history }

class _ReportPageState extends State<ReportPage> {
  ReportTab _selectedTab = ReportTab.reason;
  late Future<List<Map<String, dynamic>>> _futureCategories;
  late Future<List<Map<String, dynamic>>> _futureReports;

  String _searchKeyword = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureCategories = fetchReportCategories();
    _futureReports = fetchReportHistory(); // 신고 내역도 같이 초기화
  }

  Future<List<Map<String, dynamic>>> fetchReportCategories() async {
    final data = await Supabase.instance.client
        .from('report_category')
        .select('report_reason, reason, is_active')
        .order('report_reason');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchReportHistory() async {
    final data = await Supabase.instance.client.from('report').select('''
        report_id,
        bread_req (
          req_id,
          is_hidden,
          unique_id,
          profiles (
            name,
            cellphone
          )
        ),
        report_category (
          reason
        )
      ''');
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

  void _showDeleteDialog(int isReportCategory, int reportId) {
    showDialog(
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
                            // 실제 삭제 진행
                            try {
                              if (isReportCategory == 1) {
                                await Supabase.instance.client
                                    .from('report_category')
                                    .delete()
                                    .eq('report_reason', reportId);
                                setState(() {
                                  _futureCategories = fetchReportCategories();
                                });
                              }
                              else {
                                await Supabase.instance.client
                                    .from('report')
                                    .delete()
                                    .eq('report_id', reportId);
                                setState(() {
                                  _futureReports = fetchReportHistory();
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('삭제 실패: $e')),
                              );
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
          ),
        );
      },
    );
  }

void _showAddReasonDialog() {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width * 0.5; // 화면의 절반
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: SizedBox(
            width: dialogWidth,
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
                  SizedBox(height: 8),
                  Text(
                    '신고 사유 추가',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: '신고 사유',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason = _reasonController.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('신고 사유를 입력해주세요.')),
                          );
                          return;
                        }
                        try {
                          await Supabase.instance.client
                              .from('report_category')
                              .insert({'reason': reason, 'is_active': false});
                          setState(() {
                            _futureCategories = fetchReportCategories();
                          });
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('추가 실패: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD5A87F),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('저장하기'),
                    ),
                  ),
                  SizedBox(height: 8),
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
          // 상단: 타이틀 + 버튼 2개 + (오른쪽 추가/검색)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '신고 관리',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 24),
              _buildTabButton(
                context: context,
                label: '신고 사유항목 관리',
                selected: _selectedTab == ReportTab.reason,
                onTap: () => setState(() => _selectedTab = ReportTab.reason),
              ),
              SizedBox(width: 10),
              _buildTabButton(
                context: context,
                label: '신고 내역 관리',
                selected: _selectedTab == ReportTab.history,
                onTap: () => setState(() => _selectedTab = ReportTab.history),
              ),
              Spacer(),
              if (_selectedTab == ReportTab.reason)
                ElevatedButton(
                  onPressed: _showAddReasonDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text('추가하기', style: TextStyle(fontSize: 16)),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '검색 (이름 또는 번호를 입력해주세요.)',
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
                  ],
                ),
            ],
          ),
          SizedBox(height: 28),
          // ✅ 신고 사유항목 관리
          if (_selectedTab == ReportTab.reason)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터 불러오기 오류: ${snapshot.error}'),
                    );
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return Center(child: Text('신고 사유 항목이 없습니다.'));
                  }
                  return LayoutBuilder(
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
                                DataColumn(label: Text('신고 사유')),
                                DataColumn(label: Text('활성화')),
                                DataColumn(label: Text('삭제')),
                              ],
                              rows: categories.map((cat) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(cat['report_reason'].toString()),
                                    ),
                                    DataCell(Text(cat['reason'] ?? '')),
                                    DataCell(
                                      Switch(
                                        value: cat['is_active'] ?? false,
                                        onChanged: (bool value) async {
                                          try {
                                            await Supabase.instance.client
                                                .from('report_category')
                                                .update({'is_active': value})
                                                .eq(
                                                  'report_reason',
                                                  cat['report_reason'],
                                                );
                                            // 데이터 새로고침
                                            setState(() {
                                              _futureCategories =
                                                  fetchReportCategories();
                                            });
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('업데이트 실패: $e'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      ElevatedButton(
                                        onPressed: () {
                                          _showDeleteDialog(
                                            1, // 1은 신고 사유 삭제
                                            cat['report_reason'],
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
                  );
                },
              ),
            )
          else if (_selectedTab == ReportTab.history)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureReports,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터 불러오기 오류: ${snapshot.error}'),
                    );
                  }
                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return Center(child: Text('신고 내역이 없습니다.'));
                  }
                  final filteredReports = _searchKeyword.isEmpty
                      ? reports
                      : reports.where((report) {
                          final breadReq = report['bread_req'] ?? {};
                          final profile = breadReq['profiles'] ?? {};
                          final name = (profile['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final phone = (profile['cellphone'] ?? '').toString();
                          final keyword = _searchKeyword.toLowerCase();
                          return name.contains(keyword) ||
                              phone.contains(_searchKeyword);
                        }).toList();

                  // 페이지네이션 로직
                  final total = filteredReports.length;
                  final totalPages = (total / _rowsPerPage).ceil().clamp(1, 999);
                  final startIdx = (_currentPage - 1) * _rowsPerPage;
                  final endIdx = (startIdx + _rowsPerPage).clamp(0, total);
                  final visibleReports = filteredReports.sublist(startIdx, endIdx);

                  if (visibleReports.isEmpty) {
                    return Center(child: Text('검색 결과가 없습니다.'));
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
                                    columnSpacing: 24,
                                    columns: [
                                      DataColumn(label: Text('신고 ID')),
                                      DataColumn(label: Text('신고자 이름')),
                                      DataColumn(label: Text('전화번호')),
                                      DataColumn(label: Text('신고 사유')),
                                      DataColumn(label: Text('작성글 숨김')),
                                      DataColumn(label: Text('작성글 삭제')),
                                    ],
                                    rows: visibleReports.map((row) {
                                      final breadReq = row['bread_req'] ?? {};
                                      final profile = breadReq['profiles'] ?? {};
                                      final reportCategory =
                                          row['report_category'] ?? {};
                                      final hidden = breadReq['is_hidden'] ?? false;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(row['report_id'].toString())),
                                          DataCell(Text(profile['name'] ?? '')),
                                          DataCell(Text(profile['cellphone'] ?? '')),
                                          DataCell(
                                            Text(reportCategory['reason'] ?? ''),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: breadReq['is_hidden'] ?? false,
                                              onChanged: (bool value) async {
                                                try {
                                                  await Supabase.instance.client
                                                      .from('bread_req')
                                                      .update({'is_hidden': value})
                                                      .eq(
                                                        'req_id',
                                                        breadReq['req_id'],
                                                      );
                                                  setState(() {
                                                    _futureReports =
                                                        fetchReportHistory();
                                                  });
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '숨김 상태 변경 실패: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            ElevatedButton(
                                              onPressed: () {
                                                _showDeleteDialog(
                                                  0, // 0은 신고 내역 삭제
                                                  row['report_id'],
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[300],
                                                foregroundColor: Colors.black,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
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

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
