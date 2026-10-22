class WifiQrResult {
  final String ssid;
  final String password;
  final String securityType;
  final bool isHidden;

  const WifiQrResult({
    required this.ssid,
    required this.password,
    this.securityType = 'WPA',
    this.isHidden = false,
  });
}

class WifiQrParser {
  WifiQrParser._();

  /// Parses standard ZXing Wi-Fi QR code strings:
  /// e.g. "WIFI:S:HomeNet;T:WPA;P:SuperSecret123;H:false;;"
  static WifiQrResult? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    if (!text.toUpperCase().startsWith('WIFI:')) {
      return null;
    }

    String ssid = '';
    String password = '';
    String securityType = 'WPA';
    bool isHidden = false;

    // Remove leading 'WIFI:' or 'wifi:'
    final body = text.substring(5);

    // Tokens are separated by semicolons not preceded by a backslash
    // Standard format uses keys: S: (SSID), P: (Password), T: (Type), H: (Hidden)
    final regex = RegExp(r'([A-Z]):((?:\\;|[^;])*)');
    final matches = regex.allMatches(body);

    for (final match in matches) {
      final key = match.group(1);
      final value = _unescape(match.group(2) ?? '');

      if (key == 'S') {
        ssid = value;
      } else if (key == 'P') {
        password = value;
      } else if (key == 'T') {
        securityType = value.isEmpty ? 'WPA' : value.toUpperCase();
      } else if (key == 'H') {
        isHidden = value.toLowerCase() == 'true';
      }
    }

    if (ssid.isEmpty && password.isEmpty) {
      return null;
    }

    return WifiQrResult(
      ssid: ssid,
      password: password,
      securityType: securityType,
      isHidden: isHidden,
    );
  }

  static String _unescape(String val) {
    return val
        .replaceAll(r'\;', ';')
        .replaceAll(r'\:', ':')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\\', r'\');
  }
}
