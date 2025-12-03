import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ✅ 지도 표시용 패키지
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const RunTripApp());
}

class RunTripApp extends StatelessWidget {
  const RunTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F8FC);

    return MaterialApp(
      title: '러닝트립',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _cities = ['서울', '부산', '대구', '제주'];
  int _selectedCityIndex = 0;
  int _currentIndex = 0;

  // 🔹 로그인 상태 관련
  String? _token;
  Map<String, dynamic>? _currentUser;

  bool get _isLoggedIn => _token != null;

  // 🔹 코스 리스트로 이동 (로그인 안 되어 있으면 로그인부터)
  Future<void> _navigateToCourses({String? ctprvn}) async {
    if (!_isLoggedIn) {
      // 로그인 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코스를 보려면 먼저 로그인 해주세요.')),
      );

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _token = result['token'] as String?;
          _currentUser = result['user'] as Map<String, dynamic>?;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_currentUser?['nickname'] ?? '러너'}님, 환영합니다!',
            ),
          ),
        );
      } else {
        // 로그인 실패/취소 시 그냥 종료
        return;
      }
    }

    // 여기 도달했다 = 로그인 완료 상태
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseListPage(
          initialCity: ctprvn,
          token: _token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);

    // 각 도시별 화면
    final List<Widget> cityPages = [
      const CityPage(city: '서울'),
      const CityPage(city: '부산'),
      const CityPage(city: '대구'),
      const CityPage(city: '제주'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '러닝트립',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // “코스 찾기” 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Material(
                        color: navy,
                        child: InkWell(
                          onTap: () async {
                            // 선택된 도시를 광역시/특별시 이름으로 매핑
                            final selectedCityName =
                                _cities[_selectedCityIndex];
                            String? ctprvn;

                            switch (selectedCityName) {
                              case '서울':
                                ctprvn = '서울특별시';
                                break;
                              case '부산':
                                ctprvn = '부산광역시';
                                break;
                              case '대구':
                                ctprvn = '대구광역시';
                                break;
                              case '제주':
                                ctprvn = '제주특별자치도';
                                break;
                            }

                            await _navigateToCourses(ctprvn: ctprvn);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Center(
                              child: Text(
                                '코스 찾기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 로그인 전: 로그인/회원가입 버튼
                  //    로그인 후: 환영 문구
                  if (!_isLoggedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );

                            if (result != null &&
                                result is Map<String, dynamic>) {
                              setState(() {
                                _token = result['token'] as String?;
                                _currentUser = result['user']
                                    as Map<String, dynamic>?;
                              });

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_currentUser?['nickname'] ?? '러너'}님, 환영합니다!',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: navy,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignupPage(),
                              ),
                            );
                          },
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_currentUser?['nickname'] ?? '러너'}님, 환영합니다 👋',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 선택된 도시 화면
                  Container(
                    width: double.infinity,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: IndexedStack(
                        index: _selectedCityIndex,
                        children: cityPages,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 도시 선택 칩
                  Row(
                    children: _cities.asMap().entries.map((entry) {
                      int index = entry.key;
                      String city = entry.value;
                      bool isSelected = _selectedCityIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCityIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? navy : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) async {
              setState(() => _currentIndex = index);

              // 🔹 "코스" 탭
              if (index == 1) {
                await _navigateToCourses();
              }

              // 🔹 "내 정보" 탭
              if (index == 3) {
                if (!_isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('내 정보를 보려면 먼저 로그인 해주세요.'),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyInfoPage(
                        user: _currentUser!,
                      ),
                    ),
                  );
                }
              }
            },
            selectedFontSize: 11,
            unselectedFontSize: 11,
            backgroundColor: Colors.white,
            selectedItemColor: navy,
            unselectedItemColor: const Color(0xFF9CA3AF),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.place_rounded),
                label: '코스',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_rounded),
                label: '챌린지',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: '내 정보',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 도시별 페이지 위젯
// ----------------------------------------------------
class CityPage extends StatelessWidget {
  final String city;

  const CityPage({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    // 도시별 이미지 맵핑
    final cityImages = {
      '서울': 'assets/seoul.png',
      '부산': 'assets/busan.png',
      '대구': 'assets/daegu.png',
      '제주': 'assets/jeju.png',
    };

    final imagePath = cityImages[city] ?? 'assets/seoul.png';

    return Stack(
      children: [
        // 도시별 이미지
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),

        // 도시 이름 라벨
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              city,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 회원가입 페이지
// ----------------------------------------------------
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _birthYearController = TextEditingController();

  String? _selectedGender;
  String? _selectedCity;
  String _selectedRunningLevel = 'BEGINNER';
  int? _selectedDistance;
  int? _selectedWeeklyGoal;

  bool _isLoading = false;

  // TODO: 실제 서버 주소로 변경
  final String _baseUrl = 'http://127.0.0.1:5000';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'nickname': _nicknameController.text.trim(),
          'full_name': _fullNameController.text.trim().isEmpty
              ? null
              : _fullNameController.text.trim(),
          'birth_year': _birthYearController.text.isEmpty
              ? null
              : int.tryParse(_birthYearController.text),
          'gender': _selectedGender,
          'city': _selectedCity,
          'running_level': _selectedRunningLevel,
          'preferred_distance_km': _selectedDistance,
          'weekly_goal_runs': _selectedWeeklyGoal,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 완료!')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '회원가입 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '러닝트립에 오신 것을 환영합니다 👟',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 이메일
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일 *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해주세요.';
                        }
                        if (!value.contains('@')) {
                          return '이메일 형식이 올바르지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 닉네임
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임 *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '닉네임을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호 *',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요.';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 이름 (선택)
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: '이름 (선택)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 출생연도 (선택)
                    TextFormField(
                      controller: _birthYearController,
                      decoration: const InputDecoration(
                        labelText: '출생연도 (예: 1998)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // 성별 & 도시
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '성별',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(
                                  value: 'M', child: Text('남성')),
                              DropdownMenuItem(
                                  value: 'F', child: Text('여성')),
                              DropdownMenuItem(
                                  value: 'O', child: Text('기타/선택안함')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedGender = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '주 활동 도시',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCity,
                            items: const [
                              DropdownMenuItem(
                                  value: '서울', child: Text('서울')),
                              DropdownMenuItem(
                                  value: '부산', child: Text('부산')),
                              DropdownMenuItem(
                                  value: '대구', child: Text('대구')),
                              DropdownMenuItem(
                                  value: '제주', child: Text('제주')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedCity = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 러닝 레벨
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '러닝 레벨',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedRunningLevel,
                      items: const [
                        DropdownMenuItem(
                            value: 'BEGINNER', child: Text('입문자')),
                        DropdownMenuItem(
                            value: 'INTERMEDIATE', child: Text('중급자')),
                        DropdownMenuItem(
                            value: 'ADVANCED', child: Text('상급자')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedRunningLevel = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 선호 거리 & 주간 목표
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: '선호 거리 (km)',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedDistance,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5km')),
                              DropdownMenuItem(
                                  value: 10, child: Text('10km')),
                              DropdownMenuItem(
                                  value: 21, child: Text('하프(21km)')),
                              DropdownMenuItem(
                                  value: 42, child: Text('풀(42km)')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedDistance = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: '주당 목표 러닝 횟수',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedWeeklyGoal,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1회')),
                              DropdownMenuItem(value: 2, child: Text('2회')),
                              DropdownMenuItem(value: 3, child: Text('3회')),
                              DropdownMenuItem(value: 4, child: Text('4회+')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedWeeklyGoal = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '회원가입',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 로그인 페이지
// ----------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  // TODO: 실제 서버 주소로 변경
  final String _baseUrl = 'http://127.0.0.1:5000';

  String? _token; // 페이지 내부에서만 사용 (필요시)

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        _token = data['token'];

        if (!mounted) return;

        // 🔹 로그인 성공 시, HomePage 로 토큰/유저 정보 반환
        Navigator.pop(context, {
          'token': data['token'],
          'user': data['user'],
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '로그인 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '다시 만나서 반가워요 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해주세요.';
                        }
                        if (!value.contains('@')) {
                          return '이메일 형식이 올바르지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 내 정보 페이지
// ----------------------------------------------------
class MyInfoPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const MyInfoPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user['nickname'] ?? ''}님의 러닝 프로필',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _infoRow('이메일', user['email']),
                  const Divider(),
                  _infoRow('닉네임', user['nickname']),
                  const Divider(),
                  _infoRow('러닝 레벨', _convertLevel(user['running_level'])),
                  const Divider(),
                  _infoRow('도시', user['city']),
                  const SizedBox(height: 24),
                  const Text(
                    '※ 고건우 조진원 화이팅',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value ?? '').toString(),
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _convertLevel(dynamic level) {
    switch (level) {
      case 'BEGINNER':
        return '입문자';
      case 'INTERMEDIATE':
        return '중급자';
      case 'ADVANCED':
        return '상급자';
      default:
        return (level ?? '').toString();
    }
  }
}

// ----------------------------------------------------
// 코스 모델
// ----------------------------------------------------
class Course {
  final int courseId;
  final String courseName;
  final String ctprvnName;
  final String emndnName;
  final int totalLength;
  final String? geometryWkt; // WKT 그대로 저장

  Course({
    required this.courseId,
    required this.courseName,
    required this.ctprvnName,
    required this.emndnName,
    required this.totalLength,
    this.geometryWkt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: int.parse(json['course_id'].toString()),
      courseName: json['course_name'] as String,
      ctprvnName: json['ctprvn_name'] as String,
      emndnName: json['emndn_name'] as String,
      totalLength: int.parse(json['total_length'].toString()),
      geometryWkt: json['geometry_wkt'] as String?,
    );
  }
}

// ----------------------------------------------------
// 코스 리스트 페이지
// ----------------------------------------------------
class CourseListPage extends StatefulWidget {
  final String? initialCity; // ex) "서울특별시"
  final String? initialDistrict;
  final String? token;       // 🔹 JWT 토큰

  const CourseListPage({
    super.key,
    this.initialCity,
    this.initialDistrict,
    this.token,
  });

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  // TODO: 실제 백엔드 주소로 변경
  final String _baseUrl = 'http://127.0.0.1:5000';

  bool _isLoading = false;
  List<Course> _courses = [];

  String? _selectedCity;
  String? _selectedDistrict;
  int? _maxLength;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedDistrict = widget.initialDistrict;
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{};

      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        queryParams['city'] = _selectedCity!;
      }
      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
        queryParams['district'] = _selectedDistrict!;
      }
      if (_maxLength != null) {
        queryParams['max_length'] = _maxLength.toString();
      }

      final uri =
          Uri.parse('$_baseUrl/courses').replace(queryParameters: queryParams);

      // 🔹 Authorization 헤더 추가 (로그인한 사용자만 사용 가능)
      final headers = <String, String>{};
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final res = await http.get(
        uri,
        headers: headers.isEmpty ? null : headers,
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final List list = decoded['courses'] as List;
          setState(() {
            _courses = list.map((e) => Course.fromJson(e)).toList();
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decoded['message'] ?? '코스를 불러오지 못했습니다.'),
            ),
          );
        }
      } else if (res.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다. 다시 로그인 해주세요.'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 코드: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);

    return Scaffold(
      appBar: AppBar(
        title: const Text('코스 찾기'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 필터 영역
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text('도시'),
                      items: const [
                        DropdownMenuItem(
                            value: '서울특별시', child: Text('서울')),
                        DropdownMenuItem(
                            value: '부산광역시', child: Text('부산')),
                        DropdownMenuItem(
                            value: '대구광역시', child: Text('대구')),
                        DropdownMenuItem(
                            value: '제주특별자치도', child: Text('제주')),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCity = v);
                        _fetchCourses();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: '동/구 이름 (선택)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onFieldSubmitted: (value) {
                        _selectedDistrict =
                            value.trim().isEmpty ? null : value.trim();
                        _fetchCourses();
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _courses.isEmpty
                      ? const Center(child: Text('조건에 맞는 코스가 없습니다.'))
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _courses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = _courses[index];
                            final km =
                                (c.totalLength / 1000).toStringAsFixed(1);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  c.courseName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${c.ctprvnName} ${c.emndnName}\n약 ${km}km',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CourseDetailPage(course: c),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: navy,
        onPressed: _fetchCourses,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

// ----------------------------------------------------
// 코스 상세 페이지 (지도 + WKT)
// ----------------------------------------------------
class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  // "LINESTRING(lat lon,lat lon,...)" -> List<LatLng>
  List<LatLng> _parseLinestringWKT(String? wkt) {
    if (wkt == null || wkt.isEmpty) return [];

    final start = wkt.indexOf('(');
    final end = wkt.lastIndexOf(')');
    if (start == -1 || end == -1 || end <= start + 1) return [];

    final body = wkt.substring(start + 1, end);
    final segments = body.split(',');

    final points = <LatLng>[];
    for (final seg in segments) {
      final parts = seg.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);
      if (lat == null || lon == null) continue;

      points.add(LatLng(lat, lon));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102440);
    final km = (course.totalLength / 1000).toStringAsFixed(1);

    final wkt = course.geometryWkt;
    final linePoints = _parseLinestringWKT(wkt);

    // 중심점 (없으면 서울 시청 근처)
    LatLng center = LatLng(37.5665, 126.9780);
    if (linePoints.isNotEmpty) {
      center = linePoints[linePoints.length ~/ 2];
    }

    final wktPreview = (wkt == null || wkt.isEmpty)
        ? '코스 geometry 정보가 없습니다.'
        : wkt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('코스 상세'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${course.ctprvnName} ${course.emndnName}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '총 거리 약 $km km',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 실제 지도에 코스 라인 그리기
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.runtrip',
                          ),
                          if (linePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: linePoints,
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    '코스 geometry (WKT)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Text(
                        wktPreview,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
