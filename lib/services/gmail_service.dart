import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show Client, BaseClient, BaseRequest, StreamedResponse;
import '../models/email_message.dart';
import 'auth_service.dart';

class GmailService {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Gmail API - For Google Sign-In users
  Future<List<EmailMessage>> fetchEmailsViaGmailApi({int maxResults = 20}) async {
    try {
      final accessToken = await _authService.getGoogleAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Create authenticated client
      final credentials = AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
        null,
        ['https://www.googleapis.com/auth/gmail.readonly'],
      );

      final client = authenticatedClient(
        _GoogleAuthClient(accessToken),
        credentials,
      );

      final gmailApi = gmail.GmailApi(client);
      
      // Get message list
      final messageList = await gmailApi.users.messages.list(
        'me',
        maxResults: maxResults,
        q: 'in:inbox',
      );

      final List<EmailMessage> emails = [];
      
      if (messageList.messages != null) {
        // Fetch all messages in PARALLEL - much faster!
        final futures = messageList.messages!
            .where((m) => m.id != null)
            .map((message) => gmailApi.users.messages.get(
                  'me',
                  message.id!,
                  format: 'metadata',
                  metadataHeaders: ['From', 'Subject'],
                ))
            .toList();
        
        // Wait for all API calls to complete at once
        final results = await Future.wait(futures);
        
        // Parse all results
        for (var fullMessage in results) {
          final emailMessage = _parseGmailMessage(fullMessage);
          if (emailMessage != null) {
            emails.add(emailMessage);
          }
        }
      }

      client.close();
      return emails;
    } catch (error) {
      print('Error fetching emails via Gmail API: $error');
      rethrow;
    }
  }

  EmailMessage? _parseGmailMessage(gmail.Message message) {
    try {
      final headers = message.payload?.headers ?? [];
      
      String from = '';
      String subject = '';
      
      for (var header in headers) {
        if (header.name == 'From') {
          from = header.value ?? '';
        } else if (header.name == 'Subject') {
          subject = header.value ?? '';
        }
      }

      // Use internalDate (milliseconds since epoch) instead of parsing Date header
      DateTime messageDate = DateTime.now();
      if (message.internalDate != null) {
        try {
          messageDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(message.internalDate!),
            isUtc: false,
          );
        } catch (e) {
          print('Error parsing internalDate: $e');
        }
      }

      return EmailMessage(
        id: message.id ?? '',
        from: from,
        subject: subject,
        snippet: message.snippet ?? '',
        date: messageDate,
        isRead: !(message.labelIds?.contains('UNREAD') ?? false),
      );
    } catch (error) {
      print('Error parsing Gmail message: $error');
      return null;
    }
  }

  // IMAP - For Email/Password users
  Future<List<EmailMessage>> fetchEmailsViaImap({int maxResults = 20}) async {
    try {
      final email = await _getStoredEmail();
      final appPassword = await _getStoredAppPassword();
      
      if (email == null || appPassword == null) {
        throw Exception('Email or App Password not configured');
      }

      final client = ImapClient(isLogEnabled: false);
      
      await client.connectToServer('imap.gmail.com', 993, isSecure: true);
      await client.login(email, appPassword);
      await client.selectInbox();

      final fetchResult = await client.fetchRecentMessages(
        messageCount: maxResults,
        criteria: 'BODY.PEEK[]',
      );

      final List<EmailMessage> emails = [];
      
      for (var message in fetchResult.messages) {
        final emailMessage = _parseImapMessage(message);
        if (emailMessage != null) {
          emails.add(emailMessage);
        }
      }

      await client.logout();
      
      return emails;
    } catch (error) {
      print('Error fetching emails via IMAP: $error');
      rethrow;
    }
  }

  EmailMessage? _parseImapMessage(MimeMessage message) {
    try {
      return EmailMessage(
        id: message.sequenceId?.toString() ?? '',
        from: message.from?.first.email ?? '',
        subject: message.decodeSubject() ?? 'No Subject',
        snippet: message.decodeTextPlainPart()?.substring(0, 100) ?? '',
        date: message.decodeDate() ?? DateTime.now(),
        isRead: message.isSeen,
      );
    } catch (error) {
      print('Error parsing IMAP message: $error');
      return null;
    }
  }

  // Storage for IMAP credentials
  Future<void> saveImapCredentials(String email, String appPassword) async {
    await _secureStorage.write(key: 'imap_email', value: email);
    await _secureStorage.write(key: 'imap_app_password', value: appPassword);
  }

  Future<String?> _getStoredEmail() async {
    return await _secureStorage.read(key: 'imap_email');
  }

  Future<String?> _getStoredAppPassword() async {
    return await _secureStorage.read(key: 'imap_app_password');
  }

  Future<bool> hasImapCredentials() async {
    final email = await _getStoredEmail();
    final password = await _getStoredAppPassword();
    return email != null && password != null;
  }

  Future<void> clearImapCredentials() async {
    await _secureStorage.delete(key: 'imap_email');
    await _secureStorage.delete(key: 'imap_app_password');
  }

  // Unified method - automatically chooses the right method
  Future<List<EmailMessage>> fetchEmails({int maxResults = 20}) async {
    final loginMethod = await _authService.getLoginMethod();
    
    if (loginMethod == 'google') {
      return await fetchEmailsViaGmailApi(maxResults: maxResults);
    } else {
      return await fetchEmailsViaImap(maxResults: maxResults);
    }
  }
}

// Helper class for authenticated HTTP client
class _GoogleAuthClient extends BaseClient {
  final String _token;
  final Client _client = Client();

  _GoogleAuthClient(this._token);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _client.send(request);
  }
}
