import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ndef/ndef.dart';

void main() {
  test('vcard record construction with basic fields', () {
    var record = VCardRecord(
      formattedName: 'John Doe',
      name: VCardName(familyName: 'Doe', givenName: 'John'),
      emails: ['john@example.com'],
      phones: [VCardPhone(number: '+1-555-0100', type: 'CELL')],
      organization: 'ACME Corp',
      title: 'Engineer',
    );

    expect(record.formattedName, equals('John Doe'));
    expect(record.name!.familyName, equals('Doe'));
    expect(record.name!.givenName, equals('John'));
    expect(record.emails.length, equals(1));
    expect(record.phones.length, equals(1));
    expect(record.organization, equals('ACME Corp'));
    expect(record.decodedType, equals('text/vcard'));
  });

  test('vcard record requires name or formattedName', () {
    var record = VCardRecord();
    expect(() => record.payload, throwsArgumentError);
  });

  test('vcard record payload cannot be null or empty', () {
    var record = VCardRecord();
    expect(() => record.payload = null, throwsArgumentError);
    expect(() => record.payload = Uint8List(0), throwsArgumentError);
  });

  test('vcard record round-trip encoding', () {
    var original = VCardRecord(
      formattedName: 'Jane Smith',
      name: VCardName(familyName: 'Smith', givenName: 'Jane'),
      emails: ['jane@example.com', 'jane.smith@work.com'],
      phones: [
        VCardPhone(number: '+1-555-0200', type: 'CELL'),
        VCardPhone(number: '+1-555-0201', type: 'WORK'),
      ],
      organization: 'Tech Inc',
      title: 'Manager',
      url: 'https://example.com',
      note: 'A test contact',
    );

    var encoded = encodeNdefMessage([original]);
    var decoded = decodeRawNdefMessage(encoded);

    expect(decoded.length, equals(1));
    expect(decoded[0], isA<VCardRecord>());

    var vcard = decoded[0] as VCardRecord;
    expect(vcard.formattedName, equals('Jane Smith'));
    expect(vcard.name!.familyName, equals('Smith'));
    expect(vcard.name!.givenName, equals('Jane'));
    expect(vcard.emails.length, equals(2));
    expect(vcard.emails[0], equals('jane@example.com'));
    expect(vcard.emails[1], equals('jane.smith@work.com'));
    expect(vcard.phones.length, equals(2));
    expect(vcard.phones[0].number, equals('+1-555-0200'));
    expect(vcard.phones[0].type, equals('CELL'));
    expect(vcard.phones[1].number, equals('+1-555-0201'));
    expect(vcard.phones[1].type, equals('WORK'));
    expect(vcard.organization, equals('Tech Inc'));
    expect(vcard.title, equals('Manager'));
    expect(vcard.url, equals('https://example.com'));
    expect(vcard.note, equals('A test contact'));
  });

  test('vcard record with address round-trip', () {
    var original = VCardRecord(
      formattedName: 'Bob Builder',
      addresses: [
        VCardAddress(
          type: 'WORK',
          street: '123 Main St',
          city: 'Springfield',
          region: 'IL',
          postalCode: '62701',
          country: 'USA',
        ),
      ],
    );

    var encoded = encodeNdefMessage([original]);
    var decoded = decodeRawNdefMessage(encoded);
    var vcard = decoded[0] as VCardRecord;

    expect(vcard.addresses.length, equals(1));
    expect(vcard.addresses[0].type, equals('WORK'));
    expect(vcard.addresses[0].street, equals('123 Main St'));
    expect(vcard.addresses[0].city, equals('Springfield'));
    expect(vcard.addresses[0].region, equals('IL'));
    expect(vcard.addresses[0].postalCode, equals('62701'));
    expect(vcard.addresses[0].country, equals('USA'));
  });

  test('vcard record decode real vcard payload', () {
    // A typical vCard 3.0 as would come from an NFC tag
    final vcardString = 'BEGIN:VCARD\r\n'
        'VERSION:3.0\r\n'
        'FN:Max Mustermann\r\n'
        'N:Mustermann;Max;;;\r\n'
        'EMAIL:max@example.de\r\n'
        'TEL;TYPE=CELL:+49-170-1234567\r\n'
        'TEL;TYPE=WORK:+49-69-1234567\r\n'
        'ORG:Beispiel GmbH\r\n'
        'TITLE:Gesch\u00e4ftsf\u00fchrer\r\n'
        'ADR;TYPE=WORK:;;Hauptstra\u00dfe 1;Frankfurt;Hessen;60311;Deutschland\r\n'
        'URL:https://example.de\r\n'
        'NOTE:Testnotiz\r\n'
        'END:VCARD';

    var record = VCardRecord();
    record.payload = Uint8List.fromList(utf8.encode(vcardString));

    expect(record.version, equals('3.0'));
    expect(record.formattedName, equals('Max Mustermann'));
    expect(record.name!.familyName, equals('Mustermann'));
    expect(record.name!.givenName, equals('Max'));
    expect(record.emails.length, equals(1));
    expect(record.emails[0], equals('max@example.de'));
    expect(record.phones.length, equals(2));
    expect(record.phones[0].number, equals('+49-170-1234567'));
    expect(record.phones[0].type, equals('CELL'));
    expect(record.phones[1].number, equals('+49-69-1234567'));
    expect(record.phones[1].type, equals('WORK'));
    expect(record.organization, equals('Beispiel GmbH'));
    expect(record.title, equals('Gesch\u00e4ftsf\u00fchrer'));
    expect(record.addresses.length, equals(1));
    expect(record.addresses[0].street, equals('Hauptstra\u00dfe 1'));
    expect(record.addresses[0].city, equals('Frankfurt'));
    expect(record.addresses[0].country, equals('Deutschland'));
    expect(record.url, equals('https://example.de'));
    expect(record.note, equals('Testnotiz'));
  });

  test('vcard record decode vcard 2.1 format with bare type params', () {
    final vcardString = 'BEGIN:VCARD\r\n'
        'VERSION:2.1\r\n'
        'FN:Old Format\r\n'
        'N:Format;Old;;;\r\n'
        'TEL;CELL:+1-555-1234\r\n'
        'TEL;WORK:+1-555-5678\r\n'
        'END:VCARD';

    var record = VCardRecord();
    record.payload = Uint8List.fromList(utf8.encode(vcardString));

    expect(record.version, equals('2.1'));
    expect(record.formattedName, equals('Old Format'));
    expect(record.phones.length, equals(2));
    expect(record.phones[0].number, equals('+1-555-1234'));
    expect(record.phones[0].type, equals('CELL'));
    expect(record.phones[1].number, equals('+1-555-5678'));
    expect(record.phones[1].type, equals('WORK'));
  });

  test('vcard record minimal - formattedName only', () {
    var record = VCardRecord(formattedName: 'Simple Name');

    var encoded = encodeNdefMessage([record]);
    var decoded = decodeRawNdefMessage(encoded);
    var vcard = decoded[0] as VCardRecord;

    expect(vcard.formattedName, equals('Simple Name'));
    expect(vcard.emails, isEmpty);
    expect(vcard.phones, isEmpty);
  });

  test('vcard record with special characters', () {
    var original = VCardRecord(
      formattedName: 'M\u00fcller, Hans',
      name: VCardName(familyName: 'M\u00fcller', givenName: 'Hans'),
      organization: 'Sch\u00f6ne K\u00fcnste GmbH',
    );

    var encoded = encodeNdefMessage([original]);
    var decoded = decodeRawNdefMessage(encoded);
    var vcard = decoded[0] as VCardRecord;

    expect(vcard.formattedName, equals('M\u00fcller, Hans'));
    expect(vcard.name!.familyName, equals('M\u00fcller'));
    expect(vcard.organization, equals('Sch\u00f6ne K\u00fcnste GmbH'));
  });

  test('vcard name with semicolons in components round-trips correctly', () {
    var original = VCardRecord(
      formattedName: 'Smith; Jr., John',
      name: VCardName(
        familyName: 'Smith; Jr.',
        givenName: 'John',
      ),
    );

    var encoded = encodeNdefMessage([original]);
    var decoded = decodeRawNdefMessage(encoded);
    var vcard = decoded[0] as VCardRecord;

    expect(vcard.name!.familyName, equals('Smith; Jr.'));
    expect(vcard.name!.givenName, equals('John'));
  });

  test('vcard name structured encoding/decoding', () {
    var name = VCardName(
      familyName: 'Doe',
      givenName: 'John',
      additionalNames: 'Philip',
      honorificPrefixes: 'Dr.',
      honorificSuffixes: 'Jr.',
    );

    expect(name.encode(), equals('Doe;John;Philip;Dr.;Jr.'));

    var decoded = VCardName.decode('Doe;John;Philip;Dr.;Jr.');
    expect(decoded.familyName, equals('Doe'));
    expect(decoded.givenName, equals('John'));
    expect(decoded.additionalNames, equals('Philip'));
    expect(decoded.honorificPrefixes, equals('Dr.'));
    expect(decoded.honorificSuffixes, equals('Jr.'));
  });

  test('vcard name toString', () {
    expect(VCardName(givenName: 'John', familyName: 'Doe').toString(),
        equals('John Doe'));
    expect(VCardName(familyName: 'Doe').toString(), equals('Doe'));
    expect(VCardName(givenName: 'John').toString(), equals('John'));
  });

  test('vcard phone toString', () {
    expect(VCardPhone(number: '+1-555-0100', type: 'CELL').toString(),
        equals('CELL:+1-555-0100'));
    expect(VCardPhone(number: '+1-555-0100').toString(), equals('+1-555-0100'));
  });

  test('vcard record toString', () {
    var record = VCardRecord(
      formattedName: 'Test',
      emails: ['test@example.com'],
      phones: [VCardPhone(number: '123')],
      organization: 'Org',
    );
    var str = record.toString();
    expect(str, contains('VCardRecord'));
    expect(str, contains('Test'));
    expect(str, contains('Org'));
  });

  test('vcard line unfolding', () {
    // RFC 6350: lines can be folded by inserting CRLF + space/tab
    // The CRLF + single whitespace is removed, joining the content directly
    final vcardString = 'BEGIN:VCARD\r\n'
        'VERSION:3.0\r\n'
        'FN:Very Long Name That Gets \r\n'
        ' Folded Across Lines\r\n'
        'END:VCARD';

    var record = VCardRecord();
    record.payload = Uint8List.fromList(utf8.encode(vcardString));

    expect(record.formattedName,
        equals('Very Long Name That Gets Folded Across Lines'));
  });

  test('vcard phone without type parameter', () {
    final vcardString = 'BEGIN:VCARD\r\n'
        'VERSION:3.0\r\n'
        'FN:Test\r\n'
        'TEL:+1-555-0100\r\n'
        'END:VCARD';

    var record = VCardRecord();
    record.payload = Uint8List.fromList(utf8.encode(vcardString));

    expect(record.phones.length, equals(1));
    expect(record.phones[0].number, equals('+1-555-0100'));
    expect(record.phones[0].type, isNull);
  });

  test('vcard record in NDEF message with other records', () {
    var uriRecord = UriRecord.fromString('https://example.com');
    var vcardRecord = VCardRecord(
      formattedName: 'Contact',
      emails: ['contact@example.com'],
    );

    var encoded = encodeNdefMessage([uriRecord, vcardRecord]);
    var decoded = decodeRawNdefMessage(encoded);

    expect(decoded.length, equals(2));
    expect(decoded[0], isA<UriRecord>());
    expect(decoded[1], isA<VCardRecord>());
    expect((decoded[1] as VCardRecord).formattedName, equals('Contact'));
  });
}
