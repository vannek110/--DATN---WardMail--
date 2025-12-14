import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'theme_service.dart';
import 'locale_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.modify',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'loginMethod': 'google',
          'accessToken': googleAuth.accessToken,
        };
        await _saveUserData(userData);
        return userData;
      }

      return null;
    } catch (error) {
      print('Error signing in with Google: $error');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));

    // Giữ lại ngôn ngữ & giao diện hiện tại (có thể người dùng vừa chọn ở màn hình đăng nhập)
    final currentLocale = LocaleService().locale.value;
    final currentTheme = ThemeService().themeMode.value;

    // Tải lại dữ liệu theo từng người dùng (thông báo, giao diện, ngôn ngữ)
    await NotificationService().reloadForCurrentUser();

    // Giao diện: nếu người dùng vừa chọn giao diện, ưu tiên dùng giao diện đó cho người dùng mới
    await ThemeService().loadTheme();
    if (currentTheme != ThemeService().themeMode.value) {
      await ThemeService().setThemeMode(currentTheme);
    }

    // Ngôn ngữ: nếu người dùng vừa chọn ngôn ngữ, lưu lại cho người dùng mới
    await LocaleService().loadLocale();
    if (currentLocale != null) {
      await LocaleService().setLocale(currentLocale);
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    // Luôn lấy từ SharedPreferences để giữ lại phương thức đăng nhập
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }

    // Dự phòng sang người dùng Firebase
    final User? user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      };
    }

    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();

    // Chỉ xóa dữ liệu đăng nhập, KHÔNG xóa lịch sử phân tích / thông báo
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  Future<bool> isSignedIn() async {
    return _auth.currentUser != null;
  }

  User? get currentUser => _auth.currentUser;

  // Xác thực Email/Mật khẩu
  Future<Map<String, dynamic>?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // Cập nhật tên hiển thị
        await user.updateDisplayName(displayName);

        // Gửi email xác thực
        await user.sendEmailVerification();

        final userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName,
          'photoUrl': user.photoURL,
          'emailVerified': user.emailVerified,
          'loginMethod': 'email',
        };

        await _saveUserData(userData);
        return userData;
      }

      return null;
    } catch (error) {
      print('Error signing up with email: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'emailVerified': user.emailVerified,
          'loginMethod': 'email',
        };

        await _saveUserData(userData);
        return userData;
      }

      return null;
    } catch (error) {
      print('Error signing in with email: $error');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (error) {
      print('Error sending email verification: $error');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (error) {
      print('Error reloading user: $error');
      rethrow;
    }
  }

  Future<bool> isEmailVerified() async {
    await reloadUser();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      print('Error sending password reset email: $error');
      rethrow;
    }
  }

  // Kiểm tra phương thức đăng nhập
  Future<String?> getLoginMethod() async {
    final userData = await getCurrentUser();
    return userData?['loginMethod'] as String?;
  }

  // Lấy mã thông báo truy cập Google cho API Gmail
  Future<String?> getGoogleAccessToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.accessToken;
      }
      return null;
    } catch (error) {
      print('Error getting Google access token: $error');
      return null;
    }
  }
}
