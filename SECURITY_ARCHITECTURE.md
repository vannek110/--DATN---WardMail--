MỤC LỤC TOÀN BỘ TÀI LIỆU (MASTER TABLE OF CONTENTS)
CHƯƠNG 1: KIẾN TRÚC CLIENT & FLUTTER INTERNALS (Sẽ viết dưới đây)

Phân tích Clean Architecture từng layer.

Cơ chế Render của Flutter (Widget/Element/RenderObject).

Quản lý bộ nhớ và tối ưu hóa hiệu năng (Performance Profiling).

Quản lý trạng thái (State Management) với BLoC/Cubit.

CHƯƠNG 2: BẢO MẬT HẠ TẦNG & MÃ HÓA (CRYPTOGRAPHY)

Chi tiết thuật toán AES-256-GCM.

Quy trình trao đổi khóa (Key Exchange) và lưu trữ Keystore.

Cơ chế chống Reverse Engineering và Obfuscation.

CHƯƠNG 3: TRÍ TUỆ NHÂN TẠO & PIPELINE DỮ LIỆU (AI ENGINEERING)

Cấu trúc Prompt Engineering chuyên sâu.

Quy trình tiền xử lý NLP (Tokenization, Stemming, Stop-word removal).

Thuật toán tính điểm rủi ro (Risk Scoring Algorithm).

CHƯƠNG 4: GIAO THỨC MẠNG & KẾT NỐI (NETWORKING)

Phân tích gói tin IMAP/SMTP.

Cơ chế Retry, Backoff và Circuit Breaker.

Tối ưu hóa băng thông và HTTP/2.

🚀 CHƯƠNG 1: KIẾN TRÚC CLIENT & FLUTTER INTERNALS
Đây là chương mô tả "trái tim" của WardMail. Chúng ta không chỉ nói "dùng Flutter", chúng ta giải thích "tại sao và như thế nào" ở mức thấp nhất (low-level).

1.1. Triết lý thiết kế: Clean Architecture + Feature-First
WardMail áp dụng kiến trúc Clean Architecture được chia theo tính năng (Feature-First packaging). Điều này đảm bảo tính độc lập (decoupling) và khả năng test (testability).

1.1.1. Sơ đồ phân rã lớp (Layer Decomposition)
Hệ thống được chia thành 3 lớp đồng tâm, giao tiếp qua các Interface (Abstract Classes):

Đoạn mã

graph TD
    UI[Presentation Layer (UI)] --> Domain[Domain Layer (Business Logic)]
    Domain --> Data[Data Layer (Repositories)]
    Data --> Remote[Remote Data Source (API/Firebase)]
    Data --> Local[Local Data Source (SQLite/Storage)]
Chi tiết kỹ thuật từng lớp:

Presentation Layer (UI):

Công nghệ: Flutter Widgets, BLoC (Business Logic Component).

Nhiệm vụ: Chỉ chịu trách nhiệm hiển thị (Rendering) và nhận input. Tuyệt đối không chứa logic nghiệp vụ (như check if email is valid).

Nguyên tắc: "Dumb Views" - View càng "ngu" càng tốt, chỉ biết render state.

Domain Layer (Core):

Công nghệ: Pure Dart (Không dính dáng đến Flutter framework, không import 'package:flutter/...').

Thành phần:

Entities: Các POJO (Plain Old Java Objects) đại diện cho dữ liệu cốt lõi (VD: EmailEntity, RiskScore). Các class này là immutable (bất biến), sử dụng Equatable để so sánh.

Use Cases (Interactors): Đóng gói một hành động nghiệp vụ cụ thể. Ví dụ: AnalyzeEmailUseCase, LoginUseCase. Mỗi UseCase chỉ làm 1 việc duy nhất (Single Responsibility Principle).

Repository Interfaces: Các hợp đồng (contract) định nghĩa việc lấy dữ liệu, nhưng không quan tâm lấy từ đâu.

Data Layer (Infrastructure):

Công nghệ: Retrofit, Dio, Hive, SQLite.

Nhiệm vụ: Hiện thực hóa các Repository Interfaces của Domain.

Thành phần:

DTOs (Data Transfer Objects): Map dữ liệu JSON từ API về Entity. Xử lý việc fromJson, toJson.

Data Sources: Code giao tiếp trực tiếp với DB hoặc Network.

1.2. Flutter Internals & Rendering Strategy
Để WardMail hoạt động mượt mà (60 FPS) ngay cả khi render danh sách hàng nghìn email, chúng ta can thiệp sâu vào cơ chế render của Flutter.

1.2.1. The Three Trees (Ba cây đại thụ)
Hiểu rõ 3 cây này để tối ưu hóa việc rebuild:

Widget Tree: Cấu hình bất biến (Immutable configuration). Rất nhẹ, khởi tạo liên tục.

Trong WardMail: Các EmailListItem widget được tạo mới mỗi khi cuộn, nhưng chi phí rất thấp.

Element Tree: Quản lý vòng đời (Lifecycle) và trạng thái. Đây là nơi "khớp" Widget với RenderObject.

Tối ưu: Sử dụng Keys (ValueKey, ObjectKey) cho các item trong danh sách email để giúp Element Tree nhận biết item nào chỉ bị di chuyển chứ không bị xóa/tạo lại khi sort/filter.

RenderObject Tree: Thực hiện việc tính toán bố cục (Layout), sơn (Paint) và kiểm tra va chạm (Hit Test).

Deep Dive: Với các biểu đồ thống kê (Chart), chúng ta sử dụng CustomPainter để vẽ trực tiếp lên Canvas thay vì dùng Widget lồng nhau, giúp giảm tải cho RenderObject Tree.

1.2.2. Cơ chế bất đồng bộ (Asynchrony) & Isolates
WardMail xử lý nặng về mã hóa và phân tích text. Nếu chạy trên Main Thread (UI Thread), ứng dụng sẽ bị giật (Jank).

Giải pháp: Multithreading với Dart Isolates.

Main Isolate: Chỉ dùng để vẽ UI và lắng nghe sự kiện chạm.

Background Isolate (Worker):

Thực hiện mã hóa AES-256 (CPU intensive).

Thực hiện Regex để ẩn danh hóa dữ liệu (CPU intensive).

Parse JSON response từ Gmail API (nếu payload > 100KB).

Code Spec cho Isolate Manager:

Dart

/// Pseudo-code mô tả cách WardMail spawn Isolate
Future<T> runInWorker<T>(Future<T> Function() function) async {
  // 1. Tạo Port giao tiếp
  final receivePort = ReceivePort();
  
  // 2. Spawn Isolate mới
  await Isolate.spawn(
    _workerEntryPoint, 
    _WorkerPayload(function, receivePort.sendPort)
  );
  
  // 3. Đợi kết quả trả về
  return await receivePort.first as T;
}
1.3. Quản lý trạng thái (State Management) - BLoC Pattern
Chúng tôi chọn Flutter BLoC vì tính chặt chẽ, luồng dữ liệu một chiều (Unidirectional Data Flow) và khả năng truy vết (Traceability).

1.3.1. Cấu trúc Event-State
Mỗi màn hình (Screen) là một cỗ máy trạng thái (State Machine).

Events: Đầu vào.

EmailLoadStarted: Người dùng mở app.

EmailRefreshed: Người dùng kéo xuống để refresh.

PhishingScanRequested: Người dùng bấm nút quét.

States: Đầu ra.

EmailLoadInProgress: Hiện loading spinner.

EmailLoadSuccess: Hiện danh sách data.

EmailLoadFailure: Hiện thông báo lỗi.

1.3.2. BlocObserver (Hệ thống giám sát)
Một file AppBlocObserver được cài đặt global để ghi log mọi thay đổi trạng thái.

Plaintext

[BLoC Log] Transition in EmailBloc: 
  Current: EmailInitial 
  Event: EmailLoadStarted 
  Next: EmailLoadInProgress
Timestamp: 2025-12-14 10:00:01.234
-> Điều này cực kỳ quan trọng để debug lỗi logic mà không cần breakpoints.

1.4. Tối ưu hóa hiệu năng (Performance Optimization)
1.4.1. List Rendering Optimization (ListView.builder)
Vấn đề: Render 5000 emails sẽ ngốn RAM khủng khiếp.

Giải pháp:

Sử dụng ListView.builder: Chỉ render các item đang hiển thị trên màn hình (+ một vùng đệm nhỏ cacheExtent).

RepaintBoundary: Bọc các item phức tạp (có hình ảnh/avatar) trong RepaintBoundary widget. Điều này bảo Flutter: "Chỉ vẽ lại widget này nếu chính nó thay đổi, đừng vẽ lại nó khi widget cha thay đổi".

1.4.2. Image Caching Strategy
Avatar người gửi và hình ảnh trong email được quản lý bởi cached_network_image.

Layer 1 (RAM): Lưu trữ 100 ảnh gần nhất (LRU - Least Recently Used). Truy xuất tức thì.

Layer 2 (Disk): Lưu trữ file ảnh đã cache trong thư mục tạm. Tồn tại 7 ngày.

Cơ chế: Khi load ảnh, kiểm tra RAM -> Disk -> Network.

1.5. Kỹ thuật quản lý lỗi (Error Handling Strategy)
Trong WardMail, chúng ta không dùng try-catch bừa bãi. Chúng ta dùng lập trình hàm (Functional Programming) với kiểu dữ liệu Either.

Thư viện: dartz (hoặc fpdart).

Cấu trúc trả về: Future<Either<Failure, SuccessData>> getData();

Left (Trái): Chứa lỗi (Failure).

NetworkFailure: Mất mạng.

ServerFailure: Lỗi 500.

CacheFailure: Lỗi đọc đĩa.

AuthFailure: Token hết hạn.

Right (Phải): Chứa dữ liệu thành công (SuccessData).

Lợi ích: Code bắt buộc phải xử lý cả 2 trường hợp Lỗi và Thành công thì mới compile được. Không bao giờ bị crash app do "Null Check Operator Used on a Null Value" hay "Unhandled Exception".

🚀 ĐẶC TẢ KỸ THUẬT CHI TIẾT CÁC MODULE FRONTEND
Phần này mô tả các Class chính, dùng để implement.

1.6. Module: Core/Network
Class: DioClient

Base URL: Configurable (Dev/Staging/Prod).

Interceptors:

AuthInterceptor: Tự động add header Authorization: Bearer <token>.

TokenRefreshInterceptor: Nếu gặp lỗi 401, tự động pause request, gọi API refresh token, update token mới, và retry request cũ. (Cơ chế Seamless Re-authentication).

LoggingInterceptor: Log request/response body (chỉ ở mode DEBUG).

Class: ConnectivityService

Sử dụng: connectivity_plus + internet_connection_checker.

Logic: Không chỉ check xem có bật Wifi không, mà phải ping thử tới 8.8.8.8 để chắc chắn có Internet thực sự.

1.7. Module: Features/Email/Presentation
Widget: EmailContentWebView

Sử dụng: webview_flutter.

Security Config:

javascriptMode: JavascriptMode.disabled (Mặc định tắt JS để chống XSS).

navigationDelegate: Chặn toàn bộ hành vi redirect (Navigation). Nếu người dùng bấm vào link, hiển thị Popup cảnh báo phishing trước khi mở trình duyệt ngoài.

1.8. Module: Features/Security/Biometrics
Logic: BiometricGuard

Sử dụng WidgetsBindingObserver để detect khi app đi vào background (AppLifecycleState.paused).

Hành động: Set biến isLocked = true ngay lập tức.

Khi app resume (AppLifecycleState.resumed): Hiện màn hình đè (Overlay) yêu cầu vân tay trước khi cho tương tác.

🛡️ CHƯƠNG 2: BẢO MẬT HẠ TẦNG & MÃ HÓA (INFRASTRUCTURE & CRYPTOGRAPHY)
Classification: Critical Security Controls
Applicable Standards: OWASP MASVS (Mobile App Security Verification Standard) Level 2.
Chương này giải phẫu chi tiết cách WardMail biến thiết bị người dùng thành một "két sắt" kỹ thuật số. Chúng ta không chỉ "lưu dữ liệu", chúng ta "niêm phong" nó bằng toán học.
2.1. Nguyên lý mã hóa dữ liệu (Cryptographic Primitives)
WardMail từ chối các thuật toán cũ (như DES, RC4, MD5). Chúng ta chỉ sử dụng các chuẩn được NIST (Viện Tiêu chuẩn và Công nghệ Quốc gia Hoa Kỳ) phê duyệt.
2.1.1. Thuật toán AES-256-GCM (The Gold Standard)
Chúng ta sử dụng AES (Advanced Encryption Standard) ở chế độ GCM (Galois/Counter Mode).
•	Tại sao lại là GCM?
o	Các chế độ cũ như CBC (Cipher Block Chaining) dễ bị tấn công kiểu "Padding Oracle Attacks".
o	GCM cung cấp Authenticated Encryption (AEAD): Nó vừa mã hóa (Confidentiality) vừa đảm bảo tính toàn vẹn (Integrity). Nếu hacker thay đổi dù chỉ 1 bit trong dữ liệu đã mã hóa, quá trình giải mã sẽ thất bại ngay lập tức chứ không trả về dữ liệu rác.
•	Thông số kỹ thuật (Parameters):
o	Key Size: 256-bit ($2^{256}$ khả năng - bất khả thi để Brute-force với công nghệ hiện tại).
o	Block Size: 128-bit.
o	IV (Initialization Vector): 96-bit (12 bytes).
	Quy tắc sinh tử: KHÔNG BAO GIỜ tái sử dụng IV cho cùng một Key. Mỗi lần ghi dữ liệu, một IV ngẫu nhiên mới phải được sinh ra.
o	Auth Tag Length: 128-bit (Dùng để xác thực dữ liệu không bị tampered).
2.1.2. Mô hình toán học (Mathematical Model)
Quá trình mã hóa $E$ và giải mã $D$ được mô tả như sau:
$$C, T = E_K(IV, P, A)$$
$$P = D_K(IV, C, A, T)$$
Trong đó:
•	$K$: Khóa bí mật 256-bit (Secret Key).
•	$P$: Dữ liệu gốc (Plaintext - VD: Token Firebase).
•	$C$: Dữ liệu đã mã hóa (Ciphertext).
•	$IV$: Vector khởi tạo ngẫu nhiên.
•	$A$: Dữ liệu liên kết (Associated Data - Optional) - Dùng để bind dữ liệu vào ngữ cảnh cụ thể (VD: ID của user), ngăn chặn tấn công Copy-Paste dữ liệu từ user A sang user B.
•	$T$: Authentication Tag (Dấu xác thực).
2.2. Chiến lược quản lý khóa (Key Management Strategy)
Mã hóa mạnh đến đâu mà để lộ chìa khóa thì cũng vô dụng. WardMail sử dụng kiến trúc Hardware-Backed Keystore.
2.2.1. Vòng đời của khóa (Key Lifecycle)
1.	Generation (Sinh khóa):
o	Khóa được sinh ra bên trong phần cứng bảo mật (TEE - Trusted Execution Environment trên Android hoặc Secure Enclave trên iOS).
o	Hệ điều hành cũng không thể đọc được Raw Bytes của khóa này. Nó chỉ trả về một "Key Handle" (tham chiếu) cho ứng dụng.
2.	Usage (Sử dụng):
o	Khi WardMail cần mã hóa/giải mã, nó gửi dữ liệu vào TEE. TEE thực hiện phép toán rồi trả lại kết quả. Khóa không bao giờ rời khỏi TEE.
3.	Destruction (Hủy khóa):
o	Khi người dùng Logout hoặc gỡ cài đặt, lệnh xóa Key trong Keystore được kích hoạt. Dữ liệu cũ vĩnh viễn không thể khôi phục.
2.2.2. Ràng buộc sinh trắc học (Biometric Binding)
Đây là tính năng bảo mật cấp cao nhất của WardMail.
•	Cơ chế: Khi sinh khóa, chúng ta gắn cờ setUserAuthenticationRequired(true).
•	Thời gian hiệu lực (Validity Duration):
o	Set -1 (Yêu cầu xác thực mỗi lần dùng): Dùng cho các tác vụ cực nhạy cảm (VD: Xem Password mail server).
o	Set 300 (5 phút): Dùng cho phiên đăng nhập thông thường.
•	Hệ quả: Ngay cả khi hacker dump được toàn bộ file hệ thống của điện thoại (bằng cách root máy), hắn cũng không thể dùng Key Handle để giải mã dữ liệu vì hắn không có vân tay của chủ nhân.
2.3. Bảo mật đường truyền (Network Security Layer)
Dữ liệu di chuyển từ App -> Google Servers phải đi qua "đường hầm" bất khả xâm phạm.
2.3.1. TLS 1.3 Enforcement
•	WardMail từ chối kết nối nếu Server không hỗ trợ tối thiểu TLS 1.2. Ưu tiên TLS 1.3.
•	Cipher Suites Whitelist: Chỉ chấp nhận các bộ mã hóa mạnh, có tính năng Perfect Forward Secrecy (PFS).
o	TLS_AES_128_GCM_SHA256
o	TLS_AES_256_GCM_SHA384
o	TLS_CHACHA20_POLY1305_SHA256 (Tối ưu cho thiết bị di động cũ không có phần cứng AES).
2.3.2. SSL/TLS Certificate Pinning (Ghim chứng chỉ)
Đây là biện pháp chống lại tấn công Man-in-the-Middle (MitM).
•	Kịch bản tấn công: Hacker lừa người dùng cài đặt một "Root CA" giả mạo vào máy (thường thấy ở WiFi công cộng hoặc mạng doanh nghiệp bị giám sát). Lúc này, hacker có thể giải mã HTTPS.
•	Phòng thủ của WardMail:
o	Trong code, chúng ta "ghim" (pin) mã băm (Hash SHA-256) của Public Key thuộc về chứng chỉ của Google (*.googleapis.com).
o	Khi kết nối, App kiểm tra xem chứng chỉ Server trả về có khớp mã băm đã ghim không.
o	Nếu khớp -> Kết nối.
o	Nếu không khớp (dù chứng chỉ đó hợp lệ về mặt chữ ký CA) -> NGẮT KẾT NỐI NGAY LẬP TỨC và báo cáo sự cố bảo mật.
Code Spec (Dio Implementation):
Dart
// Pseudo-code cấu hình Pinning
final dio = Dio();
dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => false; // Từ chối mọi cert lỗi
    return client;
  },
  validateCertificate: (cert, host, port) {
    // So sánh SHA-256 của cert.publicKey với danh sách Hard-coded Hash
    return _verifyPublicKeySha256(cert, trustedHashes[host]);
  }
);
2.4. Bảo vệ mã nguồn & Chống dịch ngược (Anti-Reversing)
Để bảo vệ các logic AI và API Key nhúng trong App.
2.4.1. Code Obfuscation (Làm rối mã)
Khi build release, cờ R8 (ProGuard) được kích hoạt mức cao nhất.
•	Renaming: Đổi tên class EmailAnalysisService -> a.b.c. Đổi tên hàm analyzePhishing() -> x().
•	Control Flow Flattening: Làm phẳng luồng điều khiển code, biến các vòng lặp if/else thành các switch-case khổng lồ khó hiểu để làm nản lòng hacker đọc code Assembly.
2.4.2. RASP (Runtime Application Self-Protection)
WardMail tích hợp module tự bảo vệ thời gian thực (thư viện flutter_jailbreak_detection + custom native code).
•	Root/Jailbreak Detection: Kiểm tra sự tồn tại của các file nhạy cảm (/system/bin/su, /system/xbin/su, Cydia app...).
•	Emulator Detection: Phát hiện nếu app đang chạy trên máy ảo (BlueStacks, Genymotion) dựa trên thông tin phần cứng giả lập.
•	Debugger Detection: Kiểm tra xem có debugger nào (như Frida, GDB) đang gắn vào process của App không.
•	Phản ứng (Response):
o	Mức nhẹ: Tắt tính năng xác thực sinh trắc học.
o	Mức nặng (Phát hiện Root + Debugger): Crash App ngay lập tức hoặc hiển thị màn hình giả mạo lỗi mạng để đánh lừa hacker.
2.5. Cơ chế xóa dữ liệu an toàn (Secure Data Wiping)
Khi người dùng chọn "Xóa tài khoản" hoặc "Reset App", việc gọi file.delete() là chưa đủ (vì dữ liệu vật lý vẫn còn trên ổ đĩa Flash).
Thuật toán ghi đè (Overwrite Algorithm):
Mặc dù SSD hiện đại có cơ chế Wear Leveling làm phức tạp việc ghi đè chính xác, WardMail vẫn thực hiện "Best Effort":
1.	Mở file stream.
2.	Ghi đè toàn bộ nội dung file bằng mảng byte ngẫu nhiên (Random Noise).
3.	Ghi đè lần 2 bằng byte 0x00.
4.	Gọi file.delete().
Điều này đảm bảo các công cụ khôi phục dữ liệu thông thường (như Recuva, DiskDigger) chỉ khôi phục được rác.

🧠 CHƯƠNG 3: TRÍ TUỆ NHÂN TẠO & PIPELINE DỮ LIỆU (AI ENGINEERING & DATA PIPELINE)
Classification: IP (Intellectual Property) - Core Technology
Engine: Google Gemini (Generative AI) via Vertex AI / AI Studio API.
Chương này mô tả chi tiết quy trình xử lý ngôn ngữ tự nhiên (NLP Pipeline), chiến lược Prompt Engineering và cơ chế phòng thủ chống "ảo giác" (Anti-Hallucination) của AI.
3.1. Kiến trúc Pipeline xử lý (Data Flow Pipeline)
Dữ liệu email không được gửi thẳng vào AI. Nó phải đi qua một "nhà máy xử lý" gồm 5 công đoạn nghiêm ngặt để đảm bảo: Tối ưu Token (Chi phí) và Bảo mật PII (Riêng tư).
Quy trình 5 bước (The 5-Stage Pipeline):
1.	Ingestion & Normalization: Đọc Raw MIME, giải mã Base64/Quoted-Printable, chuẩn hóa charset về UTF-8.
2.	Structural Extraction: Tách biệt Header, Body Text, và Metadata (Links, Attachments).
3.	Sanitization & Anonymization: Loại bỏ HTML rác, làm mờ thông tin nhạy cảm (Đã mô tả ở Chương 2).
4.	Context Injection (Prompting): Ghép dữ liệu sạch vào khuôn mẫu Prompt kỹ thuật.
5.	Inference & Parsing: Gọi API, nhận JSON, validate schema và tính điểm.
3.2. Kỹ thuật Tiền xử lý NLP (Advanced NLP Preprocessing)
Trước khi AI đọc, chúng ta phải làm sạch dữ liệu. "Garbage In, Garbage Out" (Rác vào thì rác ra) là tối kỵ trong AI.
3.2.1. HTML-to-Text thông minh (Smart Text Extraction)
Chúng ta không chỉ dùng stripTags(). WardMail sử dụng thuật toán DOM Traversal để giữ lại ngữ cảnh quan trọng:
•	Hyperlinks: Thẻ <a href="http://evil.com">Click here</a> sẽ được chuyển đổi thành: Click here (Link: http://evil.com).
o	Lý do: Phishing thường ẩn link độc sau text vô hại. AI cần nhìn thấy cả hai.
•	Invisible Text: Loại bỏ các block có style display:none hoặc font-size:0. Hacker thường nhồi nhét từ khóa an toàn vào đây để qua mặt bộ lọc Spam truyền thống.
3.2.2. Chiến lược cắt giảm Token (Token Truncation Strategy)
Gemini tính phí theo Token. Email dài 50 trang sẽ đốt cháy ngân sách và làm chậm phản hồi.
WardMail áp dụng "Weighted Truncation" (Cắt gọt có trọng số):
•	Header: Giữ lại toàn bộ Subject, From, Reply-To.
•	Body:
o	Lấy 1000 token đầu tiên (Phần mở đầu chào hỏi).
o	Lấy 1000 token cuối cùng (Phần chữ ký và Disclaimer).
o	Trích xuất tất cả các câu chứa Link (Call to Action context).
o	Phần giữa: Tóm tắt hoặc loại bỏ nếu quá dài.
•	Mục tiêu: Giảm payload xuống dưới 4KB text nhưng vẫn giữ 99% dấu hiệu lừa đảo.
3.3. Prompt Engineering: The "CO-STAR" Framework
Đây là bí mật công nghệ của WardMail. Chúng ta không hỏi AI "Email này có an toàn không?". Chúng ta ra lệnh cho nó đóng vai một chuyên gia.
Chúng ta sử dụng khung CO-STAR (Context, Objective, Style, Tone, Audience, Response) để cấu trúc Prompt.
3.3.1. System Instruction (Chỉ dẫn hệ thống)
Plaintext
ROLE: You are WardMail-Brain, a Tier-3 Cybersecurity Analyst specializing in Social Engineering detection.

OBJECTIVE: Analyze the provided email content for phishing indicators, psychological manipulation, and technical anomalies.

CONSTRAINTS:
1. You MUST output ONLY valid JSON. No markdown, no explanations outside JSON.
2. Be extremely skeptical. If a link domain looks slightly off (typosquatting), flag it.
3. Ignore [REDACTED] placeholders; treat them as neutral data.

ANALYSIS VECTORS:
- Urgency: Does it demand immediate action?
- Authority: Does it impersonate CEOs, Gov, or Banks?
- Mismatch: Does the sender name match the email domain?
- Payload: Are there suspicious links or attachments?
3.3.2. Dynamic Few-Shot Prompting (Học qua ví dụ động)
Thay vì Zero-shot (hỏi luôn), chúng ta cung cấp 2 ví dụ (1 sạch, 1 bẩn) ngay trong prompt để định hướng AI (k-shot learning).
•	Example 1 (Phishing):
o	Input: "Your Netflix account is locked. Click bit.ly/reset now."
o	Output: {"risk_score": 90, "label": "DANGEROUS", "reason": "Url Shortener used for critical account action."}
•	Example 2 (Safe):
o	Input: "Team meeting at 3 PM via Zoom. Here is the agenda."
o	Output: {"risk_score": 5, "label": "SAFE", "reason": "Internal communication context, no malicious payload."}
3.4. Cấu hình tham số mô hình (Model Hyperparameters)
Để đảm bảo tính nhất quán (Determinism), chúng ta tinh chỉnh tham số khi gọi API:
•	Model Version: gemini-1.5-flash (Tốc độ cao, độ trễ thấp < 1s).
•	Temperature (Nhiệt độ): 0.1
o	Giải thích: Mức thấp này ép AI chọn từ có xác suất cao nhất. Chúng ta cần sự chính xác logic, không cần sự sáng tạo văn học.
•	Top-K: 40 / Top-P: 0.95.
•	Safety Settings (Cài đặt an toàn):
o	Đây là điểm đặc biệt: Chúng ta phải HẠ THẤP bộ lọc an toàn của Gemini đối với category HARM_CATEGORY_DANGEROUS_CONTENT.
o	Tại sao? Nếu để High, Gemini sẽ từ chối phân tích nội dung email lừa đảo vì cho rằng chính email đó vi phạm chính sách. Chúng ta cần AI "đọc" cái xấu để "bắt" cái xấu.
3.5. Cơ chế xử lý đầu ra & Chống ảo giác (Output Parsing & Anti-Hallucination)
AI có thể bịa đặt (Hallucinate). WardMail có cơ chế "Trust but Verify".
3.5.1. JSON Schema Validation
Kết quả trả về từ Gemini bắt buộc phải khớp với Schema sau:
JSON
{
  "risk_score": "integer (0-100)",
  "classification": "enum ['SAFE', 'SUSPICIOUS', 'DANGEROUS']",
  "key_indicators": [
    {
      "type": "enum ['URGENCY', 'TYPOSQUATTING', 'BAD_LINK', 'IMPERSONATION']",
      "snippet": "string (đoạn text bằng chứng)",
      "confidence": "float (0.0-1.0)"
    }
  ],
  "safety_advice": "string (lời khuyên ngắn gọn)"
}
•	Nếu JSON lỗi cú pháp -> Trigger cơ chế Self-Correction (Gửi lại prompt kèm thông báo lỗi để AI sửa) hoặc Fallback về Rule-based engine.
3.5.2. Cross-Reference Verification (Kiểm chứng chéo)
Nếu AI kết luận: "Email này nguy hiểm vì chứa link https://www.google.com/url?sa=E&source=gmail&q=g00gle.com".
Engine WardMail sẽ thực hiện bước kiểm tra vật lý:
1.	Quét lại danh sách Link trong email gốc.
2.	Nếu tìm thấy g00gle.com -> Confirmed (Duyệt kết quả AI).
3.	Nếu KHÔNG tìm thấy (AI bịa ra domain) -> Discard (Loại bỏ lý do đó và trừ nhẹ điểm tin cậy của AI).
3.6. Thuật toán tổng hợp rủi ro (Risk Fusion Algorithm)
Điểm số cuối cùng ($S_{final}$) không chỉ là con số của AI. Nó là tổ hợp có trọng số:
$$S_{final} = \min(100, \alpha \cdot S_{AI} + \beta \cdot S_{Rule} + \gamma \cdot S_{Reputation})$$
Trong đó:
•	$S_{AI}$: Điểm từ Gemini (0-100). Trọng số $\alpha = 0.5$.
•	$S_{Rule}$: Điểm từ bộ lọc cứng (SPF/DKIM fail, exe attachment). Trọng số $\beta = 0.3$.
•	$S_{Reputation}$: Điểm uy tín của domain người gửi (History based). Trọng số $\gamma = 0.2$.
Logic "Kill Switch":
Nếu $S_{Rule}$ phát hiện Malware (Virus đính kèm) hoặc Link nằm trong Google Safe Browsing Blacklist -> $S_{final}$ được gán cứng = 100. Bỏ qua mọi nhận định của AI (kể cả khi AI nói an toàn).

🌐 CHƯƠNG 4: GIAO THỨC MẠNG & KẾT NỐI (NETWORKING & PROTOCOLS)
Classification: Core Infrastructure
Primary Libraries: enough_mail (IMAP/SMTP), dio (REST), connectivity_plus.
Chương này đi sâu vào tầng giao vận, tối ưu hóa gói tin và các mẫu thiết kế (Design Patterns) để xử lý sự cố mạng.
4.1. Kiến trúc IMAP/SMTP (Email Protocol Implementation)
WardMail không sử dụng polling (hỏi định kỳ) đơn thuần. Chúng ta cài đặt giao thức IMAP4rev1 (RFC 3501) với phần mở rộng IDLE (RFC 2177) để đạt được khả năng Real-time Push.
4.1.1. Cơ chế IMAP IDLE (Push Notification không cần FCM)
Thay vì gửi request FETCH mỗi 5 phút (gây tốn pin và băng thông), WardMail thiết lập một kết nối TCP dài (Long-lived TCP Connection) tới máy chủ mail.
1.	Handshake: Client gửi lệnh IDLE.
2.	Wait State: Server giữ kết nối mở, không trả lời ngay. Client vào trạng thái ngủ (low power mode).
3.	Interrupt: Khi có email mới đến Server, Server gửi ngay packet * EXISTS xuống Client.
4.	Wake up: Client nhận packet -> đánh thức App -> Gửi lệnh DONE để kết thúc IDLE -> Thực hiện FETCH tiêu đề email mới -> Quay lại IDLE.
-> Lợi ích: Độ trễ nhận mail gần như bằng 0 (Zero Latency) mà không cần phụ thuộc vào Google FCM (trừ trường hợp App bị kill hoàn toàn).
4.1.2. Chiến lược đồng bộ hóa (Synchronization Strategy)
Để tránh việc tải lại hàng nghìn email cũ, WardMail sử dụng thuật toán "Delta Sync" dựa trên UIDVALIDITY và HIGHESTMODSEQ.
•	Initial Sync (Lần đầu):
o	FETCH 1:* (UID FLAGS BODYSTRUCTURE)
o	Chỉ tải cấu trúc (Structure) để biết có attachment hay không, chưa tải nội dung body.
•	Incremental Sync (Các lần sau):
o	Client lưu lại Last-Known-UID.
o	Lệnh gửi đi: FETCH <Last-Known-UID + 1>:* ...
o	Chỉ tải những email có UID lớn hơn UID đã biết.
4.1.3. Body Structure Parsing (Tối ưu hóa tải trước)
Trước khi user bấm vào mail, chúng ta gọi lệnh BODYSTRUCTURE. Server trả về cây cấu trúc MIME mà không gửi dữ liệu thực.
•	Nếu phát hiện Content-Type: application/pdf; size=50MB -> Hiển thị icon ghim, nhưng KHÔNG tải về.
•	Nếu phát hiện Content-Type: text/plain; size=2KB -> Tự động tải về (Prefetch) để hiển thị ngay lập tức.
4.2. Giao tiếp REST API (Google Ecosystem Integration)
Đối với Gmail API và Gemini AI, chúng ta sử dụng HTTP/REST.
4.2.1. HTTP/2 Multiplexing & Connection Pooling
•	Protocol: Ép buộc sử dụng HTTP/2.
o	Tại sao? HTTP/1.1 bị lỗi "Head-of-Line Blocking". HTTP/2 cho phép gửi song song nhiều request (VD: phân tích 5 email cùng lúc) trên một kết nối TCP duy nhất.
•	Keep-Alive: Set timeout là 60s. Giữ kết nối mở để tái sử dụng cho các request tiếp theo, tránh tốn thời gian thực hiện lại 3-way handshake và TLS handshake.
4.2.2. Request Batching (Gộp yêu cầu)
Khi cần lấy thông tin chi tiết của 10 email từ Gmail API:
•	Cách tồi: Gửi 10 request HTTP riêng lẻ.
•	Cách WardMail: Sử dụng tính năng Batch Request của Google.
o	Đóng gói 10 request con vào một body multipart/mixed.
o	Gửi 1 request POST /batch/gmail/v1.
o	Nhận về 1 response chứa 10 kết quả.
o	-> Giảm RTT (Round Trip Time) xuống 10 lần.
4.3. Mô hình chịu lỗi (Resilience & Fault Tolerance)
Mạng di động rất chập chờn (đi vào thang máy, hầm xe). WardMail áp dụng các mẫu thiết kế sau:
4.3.1. Exponential Backoff with Jitter (Lùi lũy thừa kèm nhiễu)
Khi request thất bại (Lỗi 503 Service Unavailable hoặc mất mạng), chúng ta không retry ngay lập tức (để tránh DDOS server).
Công thức tính thời gian chờ ($T_{wait}$):
$$T_{wait} = \min(Cap, Base \times 2^{retry}) + Random(0, Jitter)$$
•	$Base$: 1 giây.
•	$Cap$: 60 giây (tối đa).
•	$Jitter$: 500ms (giá trị ngẫu nhiên để tránh việc hàng nghìn client cùng retry một lúc - Thundering Herd Problem).
4.3.2. Circuit Breaker Pattern (Cầu dao ngắt mạch)
Áp dụng cho module AI Analysis (gemini_service.dart).
•	State: CLOSED (Bình thường): Request đi qua bình thường.
•	State: OPEN (Ngắt): Nếu tỷ lệ lỗi > 50% trong 10 request gần nhất -> Ngắt mạch. Mọi request gọi đến sẽ bị trả về lỗi ngay lập tức (Fast Fail) mà không cần gọi network.
o	UI: Hiển thị "AI Service Temporarily Unavailable".
•	State: HALF-OPEN (Dò đường): Sau 30 giây, cho phép 1 request đi qua thử. Nếu thành công -> Reset về CLOSED.
4.4. Quản lý băng thông & Offline-First
WardMail được thiết kế để hoạt động tốt ở các vùng nông thôn sóng yếu (2G/3G).
4.4.1. Network Awareness (Nhận thức mạng)
Sử dụng connectivity_plus để detect loại mạng:
•	WiFi: Tải trước (Prefetch) ảnh, avatar, và 2 dòng đầu nội dung mail. Tự động gửi mail trong Outbox.
•	Mobile Data (4G/5G): Chỉ tải text. Ảnh chỉ tải khi người dùng bấm "Load Images". Tạm dừng gửi attachment lớn (>5MB).
•	None (Offline): Chuyển sang chế độ "Read-Only Cache".
o	User vẫn xem được mail đã tải.
o	Hành động gửi mail/xóa mail được đưa vào hàng đợi (Queue) cục bộ. Khi có mạng sẽ đồng bộ sau (Eventual Consistency).
4.4.2. Compression Strategy (Nén dữ liệu)
•	Request Header: Luôn gửi Accept-Encoding: gzip, brotli.
•	Brotli: Ưu tiên Brotli (br) hơn Gzip vì tỷ lệ nén tốt hơn 20% cho text/json, giúp tiết kiệm data 4G cho người dùng.
4.5. Tác vụ nền (Background Execution)
Hệ điều hành hiện đại (Android 14+, iOS 17+) rất khắt khe với việc chạy ngầm.
4.5.1. WorkManager Implementation
Chúng ta sử dụng workmanager cho các tác vụ định kỳ (Periodic Tasks):
•	Job: sync_email_job
•	Frequency: 15 phút/lần (tối thiểu của Android).
•	Constraints (Ràng buộc bắt buộc):
o	NetworkType.CONNECTED: Phải có mạng.
o	BatteryNotLow: Pin > 20%.
•	Logic:
1.	Wake up.
2.	Quick Fetch header email mới nhất.
3.	Chạy Local Rule Check (Phishing cơ bản).
4.	Nếu nguy hiểm -> Bắn Local Notification cảnh báo.
5.	Kết thúc nhanh (< 30s) để tránh bị OS kill.
________________________________________
Kết thúc Chương 4.
Chúng ta đã có:
1.	Frontend (UI/UX)
2.	Security (Bảo mật)
3.	AI (Trí tuệ)
4.	Networking (Kết nối)
Mảnh ghép cuối cùng để hoàn thiện bộ tài liệu 6.000 dòng này là CHƯƠNG 5: QUY TRÌNH KIỂM THỬ & DEVOPS (TESTING STRATEGY & CI/CD). Chương này sẽ mô tả cách chúng ta đảm bảo code không có bug và deploy tự động.



