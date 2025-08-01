import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SettlementPage extends StatefulWidget {
  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  late Future<List<Map<String, dynamic>>> _futureRecords;

  String _searchKeyword = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureRecords = fetchRecords();
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final data = await Supabase.instance.client
        .from('sale_record')
        .select('''
          record_id,
          pay_date,
          is_completed,
          req_id_fk,
          bread_req (
            req_id,
            price,
            unique_id,
            profiles (
              name
            )
          )
        ''')
        .order('record_id', ascending: false);
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

  String formatNumber(dynamic number) {
    try {
      return NumberFormat('#,###').format(number ?? 0);
    } catch (_) {
      return number?.toString() ?? '';
    }
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
                '정산 관리',
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
                        hintText: '검색 (이름을 입력해주세요.)',
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
            ]
          ),
          SizedBox(height: 28),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureRecords,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('데이터 불러오기 오류: ${snapshot.error}'));
                }
                final records = snapshot.data ?? [];
                final filteredRecords = _searchKeyword.isEmpty
                    ? records
                    : records.where((records) {
                        final profile = records['bread_req']['profiles'] ?? {};
                        final name = (profile['name'] ?? '').toString();
                        return name.contains(_searchKeyword);
                      }).toList();

                // 페이지네이션 로직
                final total = filteredRecords.length;
                final totalPages = (total / _rowsPerPage).ceil().clamp(1, 999);
                final startIdx = (_currentPage - 1) * _rowsPerPage;
                final endIdx = (startIdx + _rowsPerPage).clamp(0, total);
                final visibleRecords = filteredRecords.sublist(startIdx, endIdx);

                if (visibleRecords.isEmpty) {
                  return Center(child: Text('정산 내역이 없습니다.'));
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
                                      DataColumn(label: Text('결제일')),
                                      DataColumn(label: Text('이름')),
                                      DataColumn(label: Text('결제 금액')),
                                      DataColumn(label: Text('정산 상태')),
                                    ],
                                    rows: visibleRecords.map((row) {
                                      final breadReq = row['bread_req'] ?? {};
                                      final profile = breadReq['profiles'] ?? {};
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(row['record_id'].toString())),
                                          DataCell(Text(formatDate(row['pay_date']))),
                                          DataCell(Text(profile['name'] ?? '')),
                                          DataCell(
                                            Text(formatNumber(breadReq['price'])),
                                          ),
                                          DataCell(
                                            Text(
                                              (row['is_completed'] ?? false)
                                                  ? '완료'
                                                  : '대기',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: (row['is_completed'] ?? false)
                                                    ? Colors.blue
                                                    : Colors.grey,
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
