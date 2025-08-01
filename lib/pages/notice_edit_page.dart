import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'admin_layout.dart';

class NoticeEditPage extends StatefulWidget {
  final int notificationId;
  const NoticeEditPage({required this.notificationId});

  @override
  State<NoticeEditPage> createState() => _NoticeEditPageState();
}

class _NoticeEditPageState extends State<NoticeEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();

  int? _notificationDate;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    fetchNotice();
  }

  Future<void> fetchNotice() async {
    try {
      final data = await Supabase.instance.client
          .from('notification')
          .select('notification_name, notification_date, notification_detail')
          .eq('notification_id', widget.notificationId)
          .maybeSingle();

      if (data != null) {
        _nameController.text = data['notification_name'] ?? '';
        _detailController.text = data['notification_detail'] ?? '';
        _notificationDate = data['notification_date'];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 조회 실패: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await Supabase.instance.client
          .from('notification')
          .update({
            'notification_name': _nameController.text.trim(),
            'notification_detail': _detailController.text.trim(),
          })
          .eq('notification_id', widget.notificationId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지사항이 수정되었습니다!')));
      Navigator.of(context).pop(true); // true: 수정 성공으로 pop
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      setState(() => _saving = false);
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이 부분을 AppLayout, AdminLayout 등으로 감싸주세요!
    return Scaffold(
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '공지사항 수정',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          // 이하 동일
                        ],
                      ),
                    ),
                  ),
          ),


          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '공지사항 수정',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 32),
                          Text(
                            '작성일',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            formatDate(_notificationDate),
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: '공지 제목',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '제목을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          TextFormField(
                            controller: _detailController,
                            minLines: 8,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: '공지 상세내용',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '내용을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 36),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _saving ? null : _saveNotice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFD5A87F),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _saving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        '저장하기',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
