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

  @override
  void initState() {
    super.initState();
    _futureCategories = fetchReportCategories();
  }

  Future<List<Map<String, dynamic>>> fetchReportCategories() async {
    final data = await Supabase.instance.client
        .from('report_category')
        .select('report_reason, reason, is_active')
        .order('report_reason');
    return List<Map<String, dynamic>>.from(data);
  }

  void _showDeleteDialog(int reportReasonId) {
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
                              await Supabase.instance.client
                                  .from('report_category')
                                  .delete()
                                  .eq('report_reason', reportReasonId);
                              setState(() {
                                _futureCategories = fetchReportCategories();
                              });
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: 검색어 상태 저장 및 리스트 필터링
                    },
                  ),
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
            ),
          // TODO: 신고 내역 관리 탭 구현
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
