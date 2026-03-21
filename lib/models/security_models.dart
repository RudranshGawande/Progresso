import 'package:encrypt/encrypt.dart' as encrypt;

class UserSession {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType; // 'Mobile' or 'Desktop'
  final String osInfo;
  final String? ipAddress;
  final DateTime loginTime;
  final DateTime lastActive;
  final bool isCurrent;

  UserSession({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.osInfo,
    this.ipAddress,
    required this.loginTime,
    required this.lastActive,
    this.isCurrent = false,
  });

  factory UserSession.fromMap(Map<String, dynamic> map, {String? currentSessionId}) {
    return UserSession(
      id: map['_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      deviceType: map['deviceType'] ?? 'Desktop',
      osInfo: map['osInfo'] ?? 'Unknown OS',
      ipAddress: map['ipAddress'],
      loginTime: DateTime.parse(map['loginTime'] ?? DateTime.now().toIso8601String()),
      lastActive: DateTime.parse(map['lastActive'] ?? DateTime.now().toIso8601String()),
      isCurrent: map['_id']?.toString() == currentSessionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'osInfo': osInfo,
      'ipAddress': ipAddress,
      'loginTime': loginTime.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }
}

class SecuritySettings {
  final bool is2faEnabled;
  final String? twoFactorSecret; // Should be encrypted in DB
  final DateTime? lastPasswordChange;

  SecuritySettings({
    this.is2faEnabled = false,
    this.twoFactorSecret,
    this.lastPasswordChange,
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      is2faEnabled: map['2faEnabled'] ?? false,
      twoFactorSecret: map['2faSecret'],
      lastPasswordChange: map['lastPasswordChange'] != null 
          ? DateTime.parse(map['lastPasswordChange']) 
          : null,
    );
  }
}
