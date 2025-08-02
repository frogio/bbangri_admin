import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PostPage extends StatefulWidget {
  @override
  State<PostPage> createState() => _PostPageState();
}

enum PostTab { userPosts, todayBread }

class _PostPageState extends State<PostPage> {
  PostTab _selectedTab = PostTab.userPosts;
  late Future<List<Map<String, dynamic>>> _futureUserPosts;
  late Future<List<Map<String, dynamic>>> _futureTodayBread;
  final supabaseUrl = dotenv.env['SUPABASE_URL'];

  // 페이지네이션용 변수
  int _userPostsRowsPerPage = 10;
  int _userPostsCurrentPage = 1;
  int _todayBreadRowsPerPage = 10;
  int _todayBreadCurrentPage = 1;
  final _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _futureUserPosts = fetchUserPosts();
    _futureTodayBread = fetchTodayBread();
  }

  Future<List<Map<String, dynamic>>> fetchUserPosts() async {
    final data = await Supabase.instance.client
        .from('bread_req')
        .select('''
      req_id,
      req_time,
      request_name,
      images,
      detail_msg,
      is_hidden,
      unique_id,
      profiles (
        name,
        cellphone
      )
    ''')
        .order('req_id', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchTodayBread() async {
    final data = await Supabase.instance.client
        .from('today_bread')
        .select('''
      store_id,
      store_name,
      location,
      is_active
    ''')
        .order('store_id', ascending: false);
    return List<Map<String, dynamic>>.from(data);
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

  void _showDeleteDialog(int storeId) {
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
                            .from('today_bread')
                            .delete()
                            .eq('store_id', storeId);
                        setState(() {
                          _futureTodayBread = fetchTodayBread();
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

  void _showPostDetailDialog(Map<String, dynamic> row) {
    final profile = row['profiles'] ?? {};
    final List<dynamic> imageList = [];
    try {
      if (row['images'] is String) {
        imageList.addAll(List<String>.from(jsonDecode(row['images'])));
      } else if (row['images'] is List) {
        imageList.addAll(List<String>.from(row['images']));
      }
    } catch (e) {
      // 이미지 decode 실패
    }

    int _currentIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 440,
                  maxWidth: 1000,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                      SizedBox(height: 10),
                      Text(
                        row['request_name'] ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '작성자: ${profile['name'] ?? ''}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(width: 18),
                          Text(
                            '작성일: ${formatDate(row['req_time'])}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      if (imageList.isNotEmpty) ...[
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 180,
                            viewportFraction: 0.32, // 한 화면에 3개 정도 보이게 (조절 가능)
                            enableInfiniteScroll: false,
                            enlargeCenterPage: false,
                            onPageChanged: (idx, reason) {
                              setState(() {
                                _currentIndex = idx;
                              });
                            },
                          ),
                          items: imageList.map<Widget>((imgPath) {
                            final imageUrl = Supabase.instance.client.storage.from('breadreq').getPublicUrl(imgPath).toString();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: 400,
                                  height: 400,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 400,
                                    height: 400,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageList.length, (idx) {
                            return Container(
                              width: 9,
                              height: 9,
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentIndex == idx
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[400],
                              ),
                            );
                          }),
                        ),
                      ],
                      if (imageList.isNotEmpty) SizedBox(height: 16),
                      Text(
                        '내용',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: Text(
                              row['detail_msg'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
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
      },
    );
  }

  void _toggleTodayBreadActive(int storeId, bool isActive) async {
    try {
      await Supabase.instance.client
          .from('today_bread')
          .update({'is_active': isActive})
          .eq('store_id', storeId);
      setState(() {
        _futureTodayBread = fetchTodayBread();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
    }
  }

  void _onUserPostsRowsPerPageChanged(int? value) {
    if (value == null) return;
    setState(() {
      _userPostsRowsPerPage = value;
      _userPostsCurrentPage = 1;
    });
  }

  void _onUserPostsPageChanged(int page) {
    setState(() => _userPostsCurrentPage = page);
  }

  void _onTodayBreadRowsPerPageChanged(int? value) {
    if (value == null) return;
    setState(() {
      _todayBreadRowsPerPage = value;
      _todayBreadCurrentPage = 1;
    });
  }

  void _onTodayBreadPageChanged(int page) {
    setState(() => _todayBreadCurrentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 타이틀 + 버튼 2개 + (추가하기) + 페이지네이션 셀렉트
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '게시글 관리',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 24),
              _buildTabButton(
                context: context,
                label: '사용자 작성글',
                selected: _selectedTab == PostTab.userPosts,
                onTap: () => setState(() => _selectedTab = PostTab.userPosts),
              ),
              SizedBox(width: 10),
              _buildTabButton(
                context: context,
                label: '오늘의 빵집',
                selected: _selectedTab == PostTab.todayBread,
                onTap: () => setState(() => _selectedTab = PostTab.todayBread),
              ),
              Spacer(),
              if (_selectedTab == PostTab.userPosts)
                DropdownButton<int>(
                  value: _userPostsRowsPerPage,
                  items: _rowsPerPageOptions
                      .map(
                        (count) => DropdownMenuItem(
                          value: count,
                          child: Text('$count개씩'),
                        ),
                      )
                      .toList(),
                  onChanged: _onUserPostsRowsPerPageChanged,
                  borderRadius: BorderRadius.circular(8),
                ),
              if (_selectedTab == PostTab.todayBread)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 오늘의 빵집 추가하기 로직
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text('추가하기', style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(width: 18),
                    DropdownButton<int>(
                      value: _todayBreadRowsPerPage,
                      items: _rowsPerPageOptions
                          .map(
                            (count) => DropdownMenuItem(
                              value: count,
                              child: Text('$count개씩'),
                            ),
                          )
                          .toList(),
                      onChanged: _onTodayBreadRowsPerPageChanged,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 28),

          // 사용자 작성글 탭
          if (_selectedTab == PostTab.userPosts)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureUserPosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터 불러오기 오류: ${snapshot.error}'),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return Center(child: Text('작성된 게시글이 없습니다.'));
                  }
                  // 페이지네이션
                  final total = posts.length;
                  final totalPages = (total / _userPostsRowsPerPage)
                      .ceil()
                      .clamp(1, 999);
                  final startIdx =
                      (_userPostsCurrentPage - 1) * _userPostsRowsPerPage;
                  final endIdx = (startIdx + _userPostsRowsPerPage).clamp(
                    0,
                    total,
                  );
                  final visiblePosts = posts.sublist(startIdx, endIdx);

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
                                      DataColumn(label: Text('이름')),
                                      DataColumn(label: Text('번호')),
                                      DataColumn(label: Text('업로드일')),
                                      DataColumn(label: Text('작성글 숨김')),
                                    ],
                                    rows: visiblePosts.map((row) {
                                      final profile = row['profiles'] ?? {};
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(row['req_id'].toString()),
                                            onTap: () =>
                                                _showPostDetailDialog(row),
                                          ),
                                          DataCell(
                                            Text(profile['name'] ?? ''),
                                            onTap: () =>
                                                _showPostDetailDialog(row),
                                          ),
                                          DataCell(
                                            Text(profile['cellphone'] ?? ''),
                                            onTap: () =>
                                                _showPostDetailDialog(row),
                                          ),
                                          DataCell(
                                            Text(formatDate(row['req_time'])),
                                            onTap: () =>
                                                _showPostDetailDialog(row),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: row['is_hidden'] ?? false,
                                              onChanged: (bool value) async {
                                                try {
                                                  await Supabase.instance.client
                                                      .from('bread_req')
                                                      .update({
                                                        'is_hidden': value,
                                                      })
                                                      .eq(
                                                        'req_id',
                                                        row['req_id'],
                                                      );
                                                  setState(() {
                                                    _futureUserPosts =
                                                        fetchUserPosts();
                                                  });
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '업데이트 실패: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
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
                      // 페이지네이션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: _userPostsCurrentPage > 1
                                ? () => _onUserPostsPageChanged(
                                    _userPostsCurrentPage - 1,
                                  )
                                : null,
                          ),
                          for (int i = 1; i <= totalPages; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: OutlinedButton(
                                onPressed: _userPostsCurrentPage == i
                                    ? null
                                    : () => _onUserPostsPageChanged(i),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _userPostsCurrentPage == i
                                      ? Color(0xFFD5A87F).withOpacity(0.12)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: _userPostsCurrentPage == i
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
                                    color: _userPostsCurrentPage == i
                                        ? Color(0xFFD5A87F)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed: _userPostsCurrentPage < totalPages
                                ? () => _onUserPostsPageChanged(
                                    _userPostsCurrentPage + 1,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

          // 오늘의 빵집 탭
          if (_selectedTab == PostTab.todayBread)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureTodayBread,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터 불러오기 오류: ${snapshot.error}'),
                    );
                  }
                  final stores = snapshot.data ?? [];
                  if (stores.isEmpty) {
                    return Center(child: Text('등록된 빵집이 없습니다.'));
                  }
                  // 페이지네이션
                  final total = stores.length;
                  final totalPages = (total / _todayBreadRowsPerPage)
                      .ceil()
                      .clamp(1, 999);
                  final startIdx =
                      (_todayBreadCurrentPage - 1) * _todayBreadRowsPerPage;
                  final endIdx = (startIdx + _todayBreadRowsPerPage).clamp(
                    0,
                    total,
                  );
                  final visibleStores = stores.sublist(startIdx, endIdx);

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
                                      DataColumn(label: Text('가게 이름')),
                                      DataColumn(label: Text('위치')),
                                      DataColumn(label: Text('활성화')),
                                      DataColumn(label: Text('삭제')),
                                    ],
                                    rows: visibleStores.map((store) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(store['store_id'].toString()),
                                          ),
                                          DataCell(
                                            Text(store['store_name'] ?? ''),
                                          ),
                                          DataCell(
                                            Text(store['location'] ?? ''),
                                          ),
                                          DataCell(
                                            Switch(
                                              value:
                                                  store['is_active'] ?? false,
                                              onChanged: (bool value) {
                                                _toggleTodayBreadActive(
                                                  store['store_id'],
                                                  value,
                                                );
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _showDeleteDialog(
                                                    store['store_id'],
                                                  ),
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
                      SizedBox(height: 16),
                      // 페이지네이션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: _todayBreadCurrentPage > 1
                                ? () => _onTodayBreadPageChanged(
                                    _todayBreadCurrentPage - 1,
                                  )
                                : null,
                          ),
                          for (int i = 1; i <= totalPages; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: OutlinedButton(
                                onPressed: _todayBreadCurrentPage == i
                                    ? null
                                    : () => _onTodayBreadPageChanged(i),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _todayBreadCurrentPage == i
                                      ? Color(0xFFD5A87F).withOpacity(0.12)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: _todayBreadCurrentPage == i
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
                                    color: _todayBreadCurrentPage == i
                                        ? Color(0xFFD5A87F)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed: _todayBreadCurrentPage < totalPages
                                ? () => _onTodayBreadPageChanged(
                                    _todayBreadCurrentPage + 1,
                                  )
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
