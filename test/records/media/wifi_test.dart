import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';

void main() {
  group('WifiRecord', () {
    group('authentication and encryption types', () {
      test('WSC values', () {
        expect(WifiAuthenticationType.open.wscValue, 0x0001);
        expect(WifiAuthenticationType.wpa2Personal.wscValue, 0x0020);
        expect(WifiAuthenticationType.wpaWpa2Personal.wscValue, 0x0022);

        expect(WifiEncryptionType.aes.wscValue, 0x0008);
        expect(WifiEncryptionType.aesTkip.wscValue, 0x000C);
      });

      test('fromWscValue lookup', () {
        expect(WifiAuthenticationType.fromWscValue(0x0020),
            WifiAuthenticationType.wpa2Personal);
        expect(WifiAuthenticationType.fromWscValue(0x9999),
            WifiAuthenticationType.open);
        expect(WifiEncryptionType.fromWscValue(0x0008), WifiEncryptionType.aes);
      });
    });

    group('construction and validation', () {
      test('basic properties', () {
        var record = WifiRecord(
          ssid: 'TestNetwork',
          networkKey: 'password123',
          authenticationType: WifiAuthenticationType.wpa2Personal,
          encryptionType: WifiEncryptionType.aes,
          macAddress: 'AA:BB:CC:DD:EE:FF',
        );

        expect(record.ssid, 'TestNetwork');
        expect(record.networkKey, 'password123');
        expect(record.decodedType, 'application/vnd.wfa.wsc');
      });

      test('invalid MAC address throws', () {
        expect(
          () => WifiRecord(
              ssid: 'Test', networkKey: 'pass', macAddress: 'invalid'),
          throwsArgumentError,
        );
      });

      test('missing SSID throws on payload access', () {
        expect(
            () => WifiRecord(networkKey: 'pass').payload, throwsArgumentError);
      });

      test('missing password for secured network throws', () {
        expect(
          () => WifiRecord(
            ssid: 'Test',
            authenticationType: WifiAuthenticationType.wpa2Personal,
          ).payload,
          throwsArgumentError,
        );
      });

      test('empty payload throws', () {
        expect(() => WifiRecord().payload = Uint8List(0), throwsArgumentError);
      });
    });

    group('round-trip encoding', () {
      test('WPA2 with MAC address', () {
        var original = WifiRecord(
          ssid: 'MyNetwork',
          networkKey: 'mypassword123',
          authenticationType: WifiAuthenticationType.wpa2Personal,
          encryptionType: WifiEncryptionType.aes,
          macAddress: '11:22:33:44:55:66',
        );

        var encoded = encodeNdefMessage([original]);
        var decoded = decodeRawNdefMessage(encoded);

        expect(decoded.length, 1);
        expect(decoded[0], isA<WifiRecord>());

        var record = decoded[0] as WifiRecord;
        expect(record.ssid, 'MyNetwork');
        expect(record.networkKey, 'mypassword123');
        expect(record.authenticationType, WifiAuthenticationType.wpa2Personal);
        expect(record.encryptionType, WifiEncryptionType.aes);
        expect(record.macAddress, '11:22:33:44:55:66');
      });
    });

    group('decode real payloads', () {
      test('js-nfc-wifi-parser payload', () {
        final payload = Uint8List.fromList([
          16,
          14,
          0,
          62,
          16,
          38,
          0,
          1,
          1,
          16,
          69,
          0,
          11,
          87,
          76,
          65,
          78,
          45,
          56,
          50,
          67,
          81,
          90,
          54,
          16,
          3,
          0,
          2,
          0,
          34,
          16,
          15,
          0,
          2,
          0,
          12,
          16,
          39,
          0,
          16,
          52,
          57,
          53,
          54,
          52,
          52,
          53,
          54,
          56,
          48,
          51,
          57,
          48,
          50,
          54,
          51,
          16,
          32,
          0,
          6,
          255,
          255,
          255,
          255,
          255,
          255,
        ]);

        var record = WifiRecord()..payload = payload;

        expect(record.ssid, 'WLAN-82CQZ6');
        expect(record.networkKey, '4956445680390263');
        expect(
            record.authenticationType, WifiAuthenticationType.wpaWpa2Personal);
        expect(record.encryptionType, WifiEncryptionType.aesTkip);
        expect(record.networkIndex, 1);
        expect(record.macAddress, 'FF:FF:FF:FF:FF:FF');
        expect(payload[0] << 8 | payload[1], 0x100E);
      });

      test('open network payload', () {
        final payload = Uint8List.fromList([
          0x10,
          0x0E,
          0x00,
          0x25,
          0x10,
          0x26,
          0x00,
          0x01,
          0x01,
          0x10,
          0x45,
          0x00,
          0x07,
          0x6d,
          0x79,
          0x2d,
          0x73,
          0x73,
          0x69,
          0x64,
          0x10,
          0x03,
          0x00,
          0x02,
          0x00,
          0x01,
          0x10,
          0x0F,
          0x00,
          0x02,
          0x00,
          0x01,
        ]);

        var record = WifiRecord()..payload = payload;

        expect(record.ssid, 'my-ssid');
        expect(record.authenticationType, WifiAuthenticationType.open);
        expect(record.encryptionType, WifiEncryptionType.none);
        expect(record.networkIndex, 1);
      });

      test('WPA2 payload with MAC address', () {
        final payload = Uint8List.fromList([
          0x10,
          0x0E,
          0x00,
          0x45,
          0x10,
          0x26,
          0x00,
          0x01,
          0x01,
          0x10,
          0x45,
          0x00,
          0x0a,
          0x61,
          0x62,
          0x63,
          0x64,
          0x65,
          0x66,
          0x67,
          0x68,
          0x69,
          0x6a,
          0x10,
          0x03,
          0x00,
          0x02,
          0x00,
          0x20,
          0x10,
          0x0F,
          0x00,
          0x02,
          0x00,
          0x08,
          0x10,
          0x27,
          0x00,
          0x0a,
          0x31,
          0x32,
          0x33,
          0x34,
          0x35,
          0x36,
          0x37,
          0x38,
          0x39,
          0x30,
          0x10,
          0x20,
          0x00,
          0x06,
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
          0x06,
        ]);

        var record = WifiRecord()..payload = payload;

        expect(record.ssid, 'abcdefghij');
        expect(record.networkKey, '1234567890');
        expect(record.authenticationType, WifiAuthenticationType.wpa2Personal);
        expect(record.encryptionType, WifiEncryptionType.aes);
        expect(record.macAddress, '01:02:03:04:05:06');
        expect(record.networkIndex, 1);
      });
    });

    group('special cases', () {
      test('open network round-trip', () {
        var record = WifiRecord(
          ssid: 'OpenNet',
          authenticationType: WifiAuthenticationType.open,
          encryptionType: WifiEncryptionType.none,
        );
        var decoded =
            decodeRawNdefMessage(encodeNdefMessage([record]))[0] as WifiRecord;
        expect(decoded.ssid, 'OpenNet');
        expect(decoded.authenticationType, WifiAuthenticationType.open);
      });

      test('WPA3 round-trip', () {
        var record = WifiRecord(
          ssid: 'WPA3Net',
          networkKey: 'securepass',
          authenticationType: WifiAuthenticationType.wpa3Personal,
          encryptionType: WifiEncryptionType.aes,
        );
        var decoded =
            decodeRawNdefMessage(encodeNdefMessage([record]))[0] as WifiRecord;
        expect(decoded.authenticationType, WifiAuthenticationType.wpa3Personal);
      });

      test('mixed WPA/WPA2 round-trip', () {
        var record = WifiRecord(
          ssid: 'MixedNet',
          networkKey: 'mixedpass',
          authenticationType: WifiAuthenticationType.wpaWpa2Personal,
          encryptionType: WifiEncryptionType.aesTkip,
        );
        var decoded =
            decodeRawNdefMessage(encodeNdefMessage([record]))[0] as WifiRecord;
        expect(
            decoded.authenticationType, WifiAuthenticationType.wpaWpa2Personal);
        expect(decoded.encryptionType, WifiEncryptionType.aesTkip);
      });

      test('MAC address normalization', () {
        var record = WifiRecord(
          ssid: 'Test',
          networkKey: 'pass',
          macAddress: 'aa:bb:cc:dd:ee:ff',
        );
        var decoded =
            decodeRawNdefMessage(encodeNdefMessage([record]))[0] as WifiRecord;
        expect(decoded.macAddress, 'AA:BB:CC:DD:EE:FF');
      });

      test('max length SSID', () {
        var longSsid = 'A' * 32;
        var record = WifiRecord(ssid: longSsid, networkKey: 'pass');
        var decoded =
            decodeRawNdefMessage(encodeNdefMessage([record]))[0] as WifiRecord;
        expect(decoded.ssid, longSsid);
      });
    });
  });
}
