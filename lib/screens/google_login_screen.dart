/// ==============================================================================
/// MODULE: AUTHENTICATION PRESENTATION LAYER
/// COMPONENT: GOOGLE LOGIN SCREEN
/// CLASSIFICATION: PUBLIC (No Sensitive Data Displayed)
/// ==============================================================================
///
/// [Mô tả]:
/// Màn hình Entry Point chính của ứng dụng. Được thiết kế theo triết lý
/// "Google-First" để tối ưu hóa tỷ lệ chuyển đổi (Conversion Rate) và
/// giảm ma sát (Friction) cho người dùng mới.
///
/// [Trách nhiệm]:
/// 1. Trigger luồng OAuth 2.0 qua [AuthService].
/// 2. Quản lý trạng thái UI cục bộ (Loading/Error).
/// 3. Cung cấp các tiện ích phụ (Đổi ngôn ngữ, Theme) ngay từ màn login.
/// 4. Điều hướng sang luồng đăng nhập Email truyền thống (Fallback).

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/guardmail_logo.dart';
import '../localization/app_localizations.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';

class GoogleLoginScreen extends StatefulWidget {
  // Sử dụng const constructor để tối ưu hóa việc rebuild của Flutter Framework.
  // Nếu cha của widget này rebuild, instance cũ có thể được tái sử dụng.
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  // [DEPENDENCY INJECTION NOTE]:
  // Trong môi trường Production lớn, nên inject AuthService qua Provider/GetIt
  // thay vì khởi tạo trực tiếp để dễ Mocking khi viết Unit Test.
  final AuthService _authService = AuthService();

  // [STATE MANAGEMENT]:
  // Sử dụng Ephemeral State (setState) vì trạng thái này chỉ tồn tại
  // duy nhất trong màn hình này, không cần Global State (BLoC/Redux).
  bool _isLoading = false;
  String? _errorMessage;

  /// Xử lý logic đăng nhập Google.
  /// Đây là một [Async Operation] quan trọng, cần quản lý vòng đời kỹ lưỡng.
  Future<void> _handleGoogleSignIn() async {
    final l = AppLocalizations.of(context);

    // 1. UI Feedback: Bắt đầu trạng thái loading để block tương tác người dùng,
    // ngăn chặn việc bấm nút nhiều lần (Double-submit problem).
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset lỗi cũ (nếu có)
    });

    try {
      // 2. Service Call: Gọi tầng Domain/Data để thực hiện OAuth flow.
      // Hàm này có thể ném ra Exception nếu mạng lỗi hoặc User hủy.
      final result = await _authService.signInWithGoogle();
      
      // 3. Context Safety Check (QUAN TRỌNG):
      // Trước khi dùng `context` sau lệnh await, BẮT BUỘC phải check `mounted`.
      // Nếu user đã thoát màn hình trong lúc đang login, việc gọi Navigator
      // sẽ gây crash app (Exception: Looking up a deactivated widget's ancestor).
      if (result != null && mounted) {
        // Navigation: Sử dụng pushReplacement để xóa màn hình Login khỏi Back Stack.
        // User không thể bấm nút Back để quay lại màn login sau khi đã vào Home.
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        // Trường hợp user bấm hủy chọn tài khoản Google
        setState(() {
          _errorMessage = l.t('login_cancelled');
        });
      }
    } catch (error) {
      // 4. Error Handling: Catch-all cho mọi lỗi không lường trước.
      // Log error ra console hoặc Crashlytics tại đây nếu cần.
      if (mounted) {
        setState(() {
          _errorMessage = l
              .t('login_error_with_message')
              .replaceFirst('{message}', error.toString());
        });
      }
    } finally {
      // 5. Cleanup: Luôn luôn tắt loading dù thành công hay thất bại (Idempotency).
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [THEMING STRATEGY]:
    // Cache các giá trị theme ra biến cục bộ để code gọn hơn và
    // tránh gọi Theme.of(context) quá nhiều lần trong cây Widget sâu.
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;

    // Lấy instance đa ngôn ngữ
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // [SAFE AREA]: Đảm bảo nội dung không bị che bởi tai thỏ (Notch)
      // hoặc thanh điều hướng gesture của iOS/Android đời mới.
      body: SafeArea(
        child: Center(
          // [SCROLL VIEW]: Cực kỳ quan trọng.
          // Giúp tránh lỗi "Bottom Overflowed" khi bàn phím ảo hiện lên
          // hoặc khi xoay ngang màn hình (Landscape mode).
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // [UX ENHANCEMENT]:
                // Chỉ hiển thị các nút setting khi KHÔNG loading.
                // Giữ giao diện sạch sẽ khi đang xử lý tác vụ chính.
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nút chuyển đổi ngôn ngữ nhanh (Quick Language Switcher)
                          IconButton(
                            tooltip: l.t('settings_language_title'),
                            icon: const Icon(Icons.language),
                            onPressed: () {
                              final currentCode =
                                  Localizations.localeOf(context).languageCode;
                              // Toggle logic: Vi -> En -> Vi
                              final nextLocale = currentCode == 'vi'
                                  ? const Locale('en')
                                  : const Locale('vi');
                              LocaleService().setLocale(nextLocale);
                            },
                          ),
                          // Nút chuyển đổi Theme (Dark/Light Mode)
                          IconButton(
                            tooltip: isDark
                                ? l.t('theme_toggle_to_light')
                                : l.t('theme_toggle_to_dark'),
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                            ),
                            onPressed: () async {
                              // Gọi Service để lưu preference vào SharedPreferences
                              await ThemeService().toggleDark(!isDark);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // [BRANDING IDENTITY]:
                // Logo ứng dụng, được tách ra thành Widget riêng để tái sử dụng.
                const GuardMailLogo(
                  size: 80,
                  showTitle: true,
                  titleFontSize: 26,
                  spacing: 14,
                ),
                const SizedBox(height: 8),

                // Slogan / Subtitle
                Text(
                  l.t('login_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    // Sử dụng opacity thay vì màu xám cứng (hard-coded grey)
                    // để text trông tự nhiên trên cả nền sáng và tối.
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // [ERROR FEEDBACK COMPONENT]:
                // Chỉ render khi biến _errorMessage có dữ liệu.
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      // Màu nền cảnh báo thay đổi theo Theme
                      color: isDark
                          ? Colors.red.withOpacity(0.15)
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.red[700]! : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.red[200]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // [CONDITIONAL RENDERING]:
                // Thay thế toàn bộ cụm nút bấm bằng Loading Spinner khi đang xử lý.
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF4285F4))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ==========================================
                          // PRIMARY ACTION: GOOGLE SIGN IN
                          // ==========================================
                          // Thiết kế nổi bật nhất (Visual Hierarchy Level 1)
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? theme.dividerColor
                                    : const Color(0xFFDADCE0),
                                width: 1,
                              ),
                              // Shadow nhẹ tạo cảm giác nổi (Elevation)
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              // [NOTE]: Nên tải asset này về local (assets/icons/google.svg)
                              // thay vì load network để đảm bảo icon hiện ngay cả khi mạng yếu.
                              icon: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                height: 22,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback icon nếu ảnh network lỗi
                                  return const Icon(Icons.g_mobiledata_rounded,
                                      size: 24, color: Color(0xFF4285F4));
                                },
                              ),
                              // Custom UI cho chữ Google đa sắc màu
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${l.t('login_with')} ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF3C4043),
                                    ),
                                  ),
                                  // Các Span Text màu sắc đặc trưng của Google
                                  Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                  Text(
                                    'o',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA4335),
                                    ),
                                  ),
                                  Text(
                                    'o',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFBBC05),
                                    ),
                                  ),
                                  Text(
                                    'g',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                  Text(
                                    'l',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF34A853),
                                    ),
                                  ),
                                  Text(
                                    'e',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA4335),
                                    ),
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: surfaceColor,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // DIVIDER WITH TEXT
                          // Phân tách rõ ràng giữa Main Action và Secondary Action
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  l.t('login_or'),
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ==========================================
                          // SECONDARY ACTION: EMAIL LOGIN
                          // ==========================================
                          // Sử dụng Gradient để tạo điểm nhấn nhưng không lấn át nút Google
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4285F4), Color(0xFFEA4335)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4285F4).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Điều hướng sang màn hình đăng nhập Email/Password truyền thống
                                Navigator.pushNamed(context, '/email-login');
                              },
                              icon: const Icon(Icons.email_outlined, color: Colors.white),
                              label: Text(
                                l.t('login_email'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Để lộ Gradient bên dưới
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // TERTIARY ACTION: REGISTER
                          // Mức độ ưu tiên thấp nhất, dạng Text Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l.t('login_no_account'),
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/email-register');
                                },
                                child: Text(
                                  l.t('login_register_email'),
                                  style: const TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}