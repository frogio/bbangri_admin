import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class PostPage extends StatefulWidget {
  @override
  State<PostPage> createState() => _PostPageState();
}

enum PostTab { userPosts, todayBread }

class _PostPageState extends State<PostPage> {
  PostTab _selectedTab = PostTab.userPosts;
  late Future<List<Map<String, dynamic>>> _futureUserPosts;
  late Future<List<Map<String, dynamic>>> _futureTodayBread;

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
      store_info,
      location,
      images,
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
          child: IntrinsicWidth(
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

                        try {
                          // 1. 삭제 대상 today_bread row 가져오기 (store_id로)
                          final result = await Supabase.instance.client
                              .from('today_bread')
                              .select('images')
                              .eq('store_id', storeId)
                              .maybeSingle();

                          if (result != null && result['images'] != null) {
                            // 2. images 파싱 (jsonDecode)
                            List<String> imagePaths = [];
                            try {
                              final imgList = jsonDecode(result['images']);
                              if (imgList is List) {
                                imagePaths = imgList.cast<String>();
                              }
                            } catch (_) {}

                            // 3. storage에서 이미지들 삭제
                            if (imagePaths.isNotEmpty) {
                              await Supabase.instance.client.storage
                                  .from('breadreq')
                                  .remove(imagePaths);
                            }
                          }

                          // 4. row 삭제
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

  // 👇 임시파일을 today_bread로 "이동"하는 함수 (복사 후 삭제)
  Future<String> moveFileToFinalFolder(String tmpPath) async {
    final fileName = tmpPath.split('/').last;
    final finalPath = 'today_bread/$fileName';

    try {
      // 1. Download the file as bytes
      final fileBytes = await Supabase.instance.client.storage
          .from('breadreq')
          .download(tmpPath);

      // 2. Upload the bytes to the final path
      await Supabase.instance.client.storage
          .from('breadreq')
          .uploadBinary(
            finalPath,
            fileBytes,
            fileOptions: FileOptions(upsert: true),
          );
      // uploadBinary는 성공시 String, 실패시 StorageException throw

      // 3. Delete the original tmp file
      await Supabase.instance.client.storage.from('breadreq').remove([tmpPath]);

      return finalPath;
    } catch (e) {
      throw Exception('임시 파일 이동/저장 실패: $e');
    }
  }


  // 👇 임시파일 삭제 함수
  Future<void> deleteTmpFiles(List<String> tmpPaths) async {
    if (tmpPaths.isNotEmpty) {
      await Supabase.instance.client.storage.from('breadreq').remove(tmpPaths);
    }
  }

  void _showAddTodayBreadDialog() async {
    final _storeNameController = TextEditingController();
    final _locationController = TextEditingController();
    final _storeInfoController = TextEditingController();
    List<String> imagePaths = [];
    List<Uint8List> previewImages = [];
    bool isUploading = false;
    bool isSaving = false;
    final double thumbnailSize = MediaQuery.of(context).size.width / 4.0;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 👉 사진 업로드 (임시폴더)
            Future<void> pickAndUploadImage() async {
              try {
                // 로그인 후 업로드
                final uploadEmail = dotenv.env['UPLOAD_EMAIL'];
                final uploadPassword = dotenv.env['UPLOAD_PASSWORD'];
                if (uploadEmail == null || uploadPassword == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('업로드 계정 정보가 없습니다.')));
                  return;
                }
                final response = await Supabase.instance.client.auth
                    .signInWithPassword(
                      email: uploadEmail.trim(),
                      password: uploadPassword.trim(),
                    );
                if (response.user == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('업로드 계정 로그인 실패')));
                  return;
                }

                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: true,
                );
                if (result == null) return;
                setState(() => isUploading = true);

                for (var file in result.files) {
                  if (file.bytes == null) continue;
                  final filename =
                      '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                  final storagePath = 'today_bread_tmp/$filename';

                  await Supabase.instance.client.storage
                      .from('breadreq')
                      .uploadBinary(
                        storagePath,
                        file.bytes!,
                        fileOptions: FileOptions(upsert: true),
                      );

                  imagePaths.add(storagePath);
                  previewImages.add(file.bytes!);
                }
                setState(() => isUploading = false);
              } catch (e) {
                print('파일 선택 에러: $e');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('파일 선택 에러: $e')));
              }
            }

            // 👉 추가하기 (최종 저장 시, 임시파일 -> 최종폴더로 이동 후 DB 저장)
            Future<void> onAddPressed() async {
              setState(() => isSaving = true);
              final storeName = _storeNameController.text.trim();
              final location = _locationController.text.trim();
              final storeInfo = _storeInfoController.text.trim();

              if (storeName.isEmpty || location.isEmpty || storeInfo.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('모든 항목을 입력해주세요!')));
                return;
              }
              if (imagePaths.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('사진을 1장 이상 추가해주세요!')));
                return;
              }

              try {
                // 임시 파일들을 bread_req로 이동하고, 경로 저장
                List<String> finalPaths = [];
                for (final tmpPath in List<String>.from(imagePaths)) {
                  final path = await moveFileToFinalFolder(tmpPath);
                  finalPaths.add(path);
                }

                // 2. today_bread DB 저장
                await Supabase.instance.client.from('today_bread').insert({
                  'store_name': storeName,
                  'location': location,
                  'store_info': storeInfo,
                  'images': jsonEncode(finalPaths),
                  'is_active': true,
                });

                Navigator.of(context).pop(true); // <--- "추가함" 표시
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('오늘의 빵집이 추가되었습니다!')));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('추가 실패: $e')));
              } finally {
                setState(() => isSaving = false);
              }
            }

            // 👉 취소/닫기 시 임시파일 삭제
            void onClose() async {
              await deleteTmpFiles(imagePaths);
              Navigator.of(context).pop(false);
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Spacer(),
                        IconButton(icon: Icon(Icons.close), onPressed: onClose),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '오늘의 빵집 추가',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),

                    // 가게 이름
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('가게 이름', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _storeNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 지역
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('지역', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 가게 정보
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('가게 정보', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _storeInfoController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 사진
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('사진', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.add_a_photo),
                                    label: Text('사진 추가'),
                                    onPressed: isUploading
                                        ? null
                                        : pickAndUploadImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFD5A87F),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                  ),
                                  if (isUploading) ...[
                                    SizedBox(width: 10),
                                    CircularProgressIndicator(strokeWidth: 2),
                                  ],
                                ],
                              ),
                              SizedBox(height: 6),
                              if (previewImages.isNotEmpty)
                                SizedBox(
                                  height: thumbnailSize,
                                  child: InteractiveViewer(
                                    constrained: false,
                                    scaleEnabled: false,
                                    panEnabled: true,
                                    child: Row(
                                      children: List.generate(
                                        previewImages.length,
                                        (idx) {
                                          return Stack(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.memory(
                                                    previewImages[idx],
                                                    width: thumbnailSize,
                                                    height: thumbnailSize,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              // ❌ 삭제 버튼
                                              Positioned(
                                                top: 6,
                                                right: 18,
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    final pathToDelete =
                                                        imagePaths[idx];
                                                    try {
                                                      await Supabase
                                                          .instance
                                                          .client
                                                          .storage
                                                          .from('breadreq')
                                                          .remove([
                                                            pathToDelete,
                                                          ]);

                                                      setState(() {
                                                        imagePaths.removeAt(
                                                          idx,
                                                        );
                                                        previewImages.removeAt(
                                                          idx,
                                                        );
                                                      });
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '삭제 실패: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    // 추가하기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isUploading || isSaving)
                            ? null
                            : onAddPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD5A87F),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('추가 중입니다...'),
                                ],
                              )
                            : Text('추가하기', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Dialog가 닫히고 돌아왔을 때만 setState로 갱신!
    if (result == true) {
      setState(() {
        _futureTodayBread = fetchTodayBread();
      });
    }
  }

  Future<List<String>> copyImagesToTmp(List<String> originPaths) async {
    List<String> tmpPaths = [];
    for (final oldPath in originPaths) {
      try {
        final fileName = oldPath.split('/').last;
        final tmpPath = 'today_bread_tmp/$fileName';

        // 다운로드
        final bytes = await Supabase.instance.client.storage
            .from('breadreq')
            .download(oldPath);

        try {
          await Supabase.instance.client.storage.from('breadreq').remove([
            tmpPath,
          ]);
        } catch (_) {
          // 삭제 실패는 무시 가능
        }
        // 업로드(tmp로)
        await Supabase.instance.client.storage
            .from('breadreq')
            .uploadBinary(
              tmpPath,
              bytes,
              fileOptions: FileOptions(upsert: true),
            );
        tmpPaths.add(tmpPath);
      } catch (e) {
        print('기존 이미지 복사 실패: $e');
      }
    }
    return tmpPaths;
  }

  /// today_bread 폴더의 이미지 삭제
  Future<void> deleteTodayBreadImages(List<String> originPaths) async {
    if (originPaths.isNotEmpty) {
      await Supabase.instance.client.storage
          .from('breadreq')
          .remove(originPaths);
    }
  }

  /// row 클릭 시 호출되는 수정 다이얼로그
  Future<void> _showEditTodayBreadDialog(Map<String, dynamic> storeRow) async {
    final _storeNameController = TextEditingController(
      text: storeRow['store_name'] ?? '',
    );
    final _locationController = TextEditingController(
      text: storeRow['location'] ?? '',
    );
    final _storeInfoController = TextEditingController(
      text: storeRow['store_info'] ?? '',
    );

    // 기존 이미지 경로
    List<String> oldImagePaths = [];
    try {
      final imagesVal = storeRow['images'];
      if (imagesVal != null) {
        if (imagesVal is String) {
          oldImagePaths.addAll(List<String>.from(jsonDecode(imagesVal)));
        } else if (imagesVal is List) {
          oldImagePaths.addAll(List<String>.from(imagesVal));
        }
      }
    } catch (_) {}

    // today_bread_tmp에 복사
    List<String> imagePaths = await copyImagesToTmp(oldImagePaths);

    // 썸네일 미리보기용 bytes 리스트
    List<Uint8List> previewImages = [];
    for (final path in imagePaths) {
      try {
        final bytes = await Supabase.instance.client.storage
            .from('breadreq')
            .download(path);
        previewImages.add(bytes);
      } catch (e) {
        print('이미지 다운로드 실패: $e');
      }
    }

    bool isUploading = false;
    bool isSaving = false;
    final double thumbnailSize = MediaQuery.of(context).size.width / 4.0;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 이미지 추가
            Future<void> pickAndUploadImage() async {
              try {
                // 로그인 후 업로드
                final uploadEmail = dotenv.env['UPLOAD_EMAIL'];
                final uploadPassword = dotenv.env['UPLOAD_PASSWORD'];
                if (uploadEmail == null || uploadPassword == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('업로드 계정 정보가 없습니다.')));
                  return;
                }
                final response = await Supabase.instance.client.auth
                    .signInWithPassword(
                      email: uploadEmail.trim(),
                      password: uploadPassword.trim(),
                    );
                if (response.user == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('업로드 계정 로그인 실패')));
                  return;
                }

                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: true,
                );
                if (result == null) return;
                setState(() => isUploading = true);

                for (var file in result.files) {
                  if (file.bytes == null) continue;
                  final filename =
                      '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                  final storagePath = 'today_bread_tmp/$filename';

                  await Supabase.instance.client.storage
                      .from('breadreq')
                      .uploadBinary(
                        storagePath,
                        file.bytes!,
                        fileOptions: FileOptions(upsert: true),
                      );
                  imagePaths.add(storagePath);
                  previewImages.add(file.bytes!);
                }
                setState(() => isUploading = false);
              } catch (e) {
                print('파일 선택 에러: $e');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('파일 선택 에러: $e')));
              }
            }

            // 이미지 X버튼 삭제
            void onDeleteImage(int idx) async {
              final deletePath = imagePaths[idx];
              await Supabase.instance.client.storage.from('breadreq').remove([
                deletePath,
              ]);
              setState(() {
                imagePaths.removeAt(idx);
                previewImages.removeAt(idx);
              });
            }

            // 저장하기
            Future<void> onSavePressed() async {
              setState(() => isSaving = true);
              final storeName = _storeNameController.text.trim();
              final location = _locationController.text.trim();
              final storeInfo = _storeInfoController.text.trim();

              if (storeName.isEmpty || location.isEmpty || storeInfo.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('모든 항목을 입력해주세요!')));
                return;
              }
              if (imagePaths.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('사진을 1장 이상 추가해주세요!')));
                return;
              }
              try {
                // 기존 today_bread 이미지 삭제
                await deleteTodayBreadImages(oldImagePaths);

                // today_bread_tmp에 있는 이미지를 today_bread 폴더로 move
                List<String> finalPaths = [];
                for (final tmpPath in List<String>.from(imagePaths)) {
                  final path = await moveFileToFinalFolder(tmpPath);
                  finalPaths.add(path);
                }

                // DB 업데이트
                await Supabase.instance.client
                    .from('today_bread')
                    .update({
                      'store_name': storeName,
                      'location': location,
                      'store_info': storeInfo,
                      'images': jsonEncode(finalPaths),
                    })
                    .eq('store_id', storeRow['store_id']);

                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('저장 완료!')));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
              } finally {
                setState(() => isSaving = false);
              }
            }

            // 닫기: today_bread_tmp 파일만 제거
            void onClose() async {
              await deleteTmpFiles(imagePaths);
              Navigator.of(context).pop(false);
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Spacer(),
                        IconButton(icon: Icon(Icons.close), onPressed: onClose),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '오늘의 빵집 정보 수정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('가게 이름', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _storeNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('지역', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('가게 정보', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _storeInfoController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 사진
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('사진', style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.add_a_photo),
                                    label: Text('사진 추가'),
                                    onPressed: isUploading
                                        ? null
                                        : pickAndUploadImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFD5A87F),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                  ),
                                  if (isUploading) ...[
                                    SizedBox(width: 10),
                                    CircularProgressIndicator(strokeWidth: 2),
                                  ],
                                ],
                              ),
                              SizedBox(height: 6),
                              if (previewImages.isNotEmpty)
                                SizedBox(
                                  height: thumbnailSize,
                                  child: InteractiveViewer(
                                    constrained: false,
                                    scaleEnabled: false,
                                    panEnabled: true,
                                    child: Row(
                                      children: List.generate(
                                        previewImages.length,
                                        (idx) {
                                          return Stack(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.memory(
                                                    previewImages[idx],
                                                    width: thumbnailSize,
                                                    height: thumbnailSize,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              // ❌ 삭제 버튼
                                              Positioned(
                                                top: 6,
                                                right: 18,
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    final pathToDelete =
                                                        imagePaths[idx];
                                                    try {
                                                      await Supabase
                                                          .instance
                                                          .client
                                                          .storage
                                                          .from('breadreq')
                                                          .remove([
                                                            pathToDelete,
                                                          ]);

                                                      setState(() {
                                                        imagePaths.removeAt(
                                                          idx,
                                                        );
                                                        previewImages.removeAt(
                                                          idx,
                                                        );
                                                      });
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '삭제 실패: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    // 저장하기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isUploading || isSaving)
                            ? null
                            : onSavePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD5A87F),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('저장 중입니다...'),
                                ],
                              )
                            : Text('저장하기', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // 저장시만 갱신
    setState(() {
      _futureTodayBread = fetchTodayBread();
    });
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
                      onPressed: _showAddTodayBreadDialog,
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
                                            onTap: () => _showEditTodayBreadDialog(store,),
                                          ),
                                          DataCell(
                                            Text(store['store_name'] ?? ''),
                                            onTap: () => _showEditTodayBreadDialog(store,),
                                          ),
                                          DataCell(
                                            Text(store['location'] ?? ''),
                                            onTap: () =>
                                                _showEditTodayBreadDialog(
                                                  store,
                                                ),
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
                                            onTap: () =>
                                                _showEditTodayBreadDialog(
                                                  store,
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
                                            onTap: () =>
                                                _showEditTodayBreadDialog(
                                                  store,
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
