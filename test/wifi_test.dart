import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ndef/ndef.dart';

void main() {
  test('wifi authentication and encryption types', () {
    assert(WifiAuthenticationType.open.wscValue == 0x0001);
    assert(WifiAuthenticationType.wpa2Personal.wscValue == 0x0020);
    assert(WifiAuthenticationType.wpaWpa2Personal.wscValue == 0x0022);

    assert(WifiAuthenticationType.fromWscValue(0x0020) ==
        WifiAuthenticationType.wpa2Personal);
    assert(WifiAuthenticationType.fromWscValue(0x9999) ==
        WifiAuthenticationType.open);

    assert(WifiEncryptionType.aes.wscValue == 0x0008);
    assert(WifiEncryptionType.aesTkip.wscValue == 0x000C);
    assert(WifiEncryptionType.fromWscValue(0x0008) == WifiEncryptionType.aes);
  });

  test('wifi record construction and validation', () {
    var record = WifiRecord(
      ssid: 'TestNetwork',
      networkKey: 'password123',
      authenticationType: WifiAuthenticationType.wpa2Personal,
      encryptionType: WifiEncryptionType.aes,
      macAddress: 'AA:BB:CC:DD:EE:FF',
    );

    assert(record.ssid == 'TestNetwork');
    assert(record.networkKey == 'password123');
    assert(record.decodedType == 'application/vnd.wfa.wsc');

    // Invalid MAC address
    expect(
        () =>
            WifiRecord(ssid: 'Test', networkKey: 'pass', macAddress: 'invalid'),
        throwsArgumentError);

    // Missing SSID
    expect(() => WifiRecord(networkKey: 'pass').payload, throwsArgumentError);

    // Missing password for secured network
    expect(
        () => WifiRecord(
                ssid: 'Test',
                authenticationType: WifiAuthenticationType.wpa2Personal)
            .payload,
        throwsArgumentError);

    // Invalid payload
    expect(() => WifiRecord().payload = Uint8List(0), throwsArgumentError);
  });

  test('wifi record round-trip encoding', () {
    var original = WifiRecord(
      ssid: 'MyNetwork',
      networkKey: 'mypassword123',
      authenticationType: WifiAuthenticationType.wpa2Personal,
      encryptionType: WifiEncryptionType.aes,
      macAddress: '11:22:33:44:55:66',
    );

    var encoded = encodeNdefMessage([original]);
    var decoded = decodeRawNdefMessage(encoded);

    assert(decoded.length == 1);
    assert(decoded[0] is WifiRecord);

    var wifiRecord = decoded[0] as WifiRecord;
    assert(wifiRecord.ssid == 'MyNetwork');
    assert(wifiRecord.networkKey == 'mypassword123');
    assert(
        wifiRecord.authenticationType == WifiAuthenticationType.wpa2Personal);
    assert(wifiRecord.encryptionType == WifiEncryptionType.aes);
    assert(wifiRecord.macAddress == '11:22:33:44:55:66');
  });

  test('wifi record decode real NFC payload from js-nfc-wifi-parser', () {
    // Real NFC WiFi payload from https://github.com/gfnork/js-nfc-wifi-parser/blob/master/test/mocks/nfc-payload.json
    final payload = Uint8List.fromList([
      16, 14, 0, 62, // Credential container (0x100E), length 62
      16, 38, 0, 1, 1, // Network Index (0x1026) = 1
      16, 69, 0, 11, 87, 76, 65, 78, 45, 56, 50, 67, 81, 90,
      54, // SSID = "WLAN-82CQZ6"
      16, 3, 0, 2, 0, 34, // Auth Type (0x1003) = 0x0022 (WPA/WPA2-Personal)
      16, 15, 0, 2, 0, 12, // Encryption Type (0x100F) = 0x000C (AES/TKIP)
      16, 39, 0, 16, 52, 57, 53, 54, 52, 52, 53, 54, 56, 48, 51, 57, 48, 50, 54,
      51, // Network Key = "4956445680390263"
      16, 32, 0, 6, 255, 255, 255, 255, 255,
      255, // MAC Address = FF:FF:FF:FF:FF:FF
    ]);

    var record = WifiRecord();
    record.payload = payload;

    assert(record.ssid == 'WLAN-82CQZ6');
    assert(record.networkKey == '4956445680390263');
    assert(record.authenticationType == WifiAuthenticationType.wpaWpa2Personal);
    assert(record.encryptionType == WifiEncryptionType.aesTkip);
    assert(record.networkIndex == 1);
    assert(record.macAddress == 'FF:FF:FF:FF:FF:FF');

    // Verify credential container starts with 0x100E
    assert((payload[0] << 8 | payload[1]) == 0x100E);
  });

  test('wifi record decode open network payload', () {
    // Real NFC WiFi payload from https://github.com/nfcpy/ndeflib/blob/master/tests/test_wifi.py
    final payload = Uint8List.fromList([
      0x10, 0x0E, 0x00, 0x25, // Credential container (0x100E), length 37
      0x10, 0x26, 0x00, 0x01, 0x01, // Network Index = 1
      0x10, 0x45, 0x00, 0x07, 0x6d, 0x79, 0x2d, 0x73, 0x73, 0x69,
      0x64, // SSID = "my-ssid"
      0x10, 0x03, 0x00, 0x02, 0x00, 0x01, // Auth Type = Open (0x0001)
      0x10, 0x0F, 0x00, 0x02, 0x00, 0x01, // Encryption Type = None (0x0001)
    ]);

    var record = WifiRecord();
    record.payload = payload;

    assert(record.ssid == 'my-ssid');
    assert(record.authenticationType == WifiAuthenticationType.open);
    assert(record.encryptionType == WifiEncryptionType.none);
    assert(record.networkIndex == 1);
  });

  test('wifi record decode WPA2 payload with MAC address', () {
    // Real NFC WiFi payload from https://github.com/nfcpy/ndeflib/blob/master/tests/test_wifi.py
    final payload = Uint8List.fromList([
      0x10, 0x0E, 0x00, 0x45, // Credential container, length 69
      0x10, 0x26, 0x00, 0x01, 0x01, // Network Index = 1
      0x10, 0x45, 0x00, 0x0a, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
      0x69, 0x6a, // SSID = "abcdefghij"
      0x10, 0x03, 0x00, 0x02, 0x00, 0x20, // Auth Type = WPA2-Personal (0x0020)
      0x10, 0x0F, 0x00, 0x02, 0x00, 0x08, // Encryption Type = AES (0x0008)
      0x10, 0x27, 0x00, 0x0a, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
      0x39, 0x30, // Network Key = "1234567890"
      0x10, 0x20, 0x00, 0x06, 0x01, 0x02, 0x03, 0x04, 0x05,
      0x06, // MAC Address = 01:02:03:04:05:06
    ]);

    var record = WifiRecord();
    record.payload = payload;

    assert(record.ssid == 'abcdefghij');
    assert(record.networkKey == '1234567890');
    assert(record.authenticationType == WifiAuthenticationType.wpa2Personal);
    assert(record.encryptionType == WifiEncryptionType.aes);
    assert(record.macAddress == '01:02:03:04:05:06');
    assert(record.networkIndex == 1);
  });

  test('wifi record special cases', () {
    // Open network
    var openRecord = WifiRecord(
      ssid: 'OpenNet',
      authenticationType: WifiAuthenticationType.open,
      encryptionType: WifiEncryptionType.none,
    );
    var encoded = encodeNdefMessage([openRecord]);
    var decoded = decodeRawNdefMessage(encoded);
    var decodedWifi = decoded[0] as WifiRecord;
    assert(decodedWifi.ssid == 'OpenNet');
    assert(decodedWifi.authenticationType == WifiAuthenticationType.open);

    // WPA3 Personal
    var wpa3Record = WifiRecord(
      ssid: 'WPA3Net',
      networkKey: 'securepass',
      authenticationType: WifiAuthenticationType.wpa3Personal,
      encryptionType: WifiEncryptionType.aes,
    );
    encoded = encodeNdefMessage([wpa3Record]);
    decoded = decodeRawNdefMessage(encoded);
    decodedWifi = decoded[0] as WifiRecord;
    assert(
        decodedWifi.authenticationType == WifiAuthenticationType.wpa3Personal);

    // Mixed WPA/WPA2
    var mixedRecord = WifiRecord(
      ssid: 'MixedNet',
      networkKey: 'mixedpass',
      authenticationType: WifiAuthenticationType.wpaWpa2Personal,
      encryptionType: WifiEncryptionType.aesTkip,
    );
    encoded = encodeNdefMessage([mixedRecord]);
    decoded = decodeRawNdefMessage(encoded);
    decodedWifi = decoded[0] as WifiRecord;
    assert(decodedWifi.authenticationType ==
        WifiAuthenticationType.wpaWpa2Personal);
    assert(decodedWifi.encryptionType == WifiEncryptionType.aesTkip);

    // MAC address normalization (lowercase to uppercase)
    var macRecord = WifiRecord(
      ssid: 'Test',
      networkKey: 'pass',
      macAddress: 'aa:bb:cc:dd:ee:ff',
    );
    encoded = encodeNdefMessage([macRecord]);
    decoded = decodeRawNdefMessage(encoded);
    decodedWifi = decoded[0] as WifiRecord;
    assert(decodedWifi.macAddress == 'AA:BB:CC:DD:EE:FF');

    // Long SSID (32 chars max)
    var longSsid = 'A' * 32;
    var longSsidRecord = WifiRecord(ssid: longSsid, networkKey: 'pass');
    encoded = encodeNdefMessage([longSsidRecord]);
    decoded = decodeRawNdefMessage(encoded);
    decodedWifi = decoded[0] as WifiRecord;
    assert(decodedWifi.ssid == longSsid);
  });
}
