import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/data/local_data.dart';

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle({
    this.strings = const <String, String>{},
    this.errorKeys = const <String>{},
  });

  final Map<String, String> strings;
  final Set<String> errorKeys;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (errorKeys.contains(key)) {
      throw FlutterError('Unable to load asset $key');
    }
    final String? value = strings[key];
    if (value == null) {
      throw FlutterError('Missing asset: $key');
    }
    return value;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError('Binary load is not supported in tests.');
  }

  @override
  void evict(String key) {}
}

void main() {
  const String usersKey = 'assets/data/users.json';
  const String requestsKey = 'assets/data/match_requests.json';

  setUp(() {
    LocalData().resetForTesting();
  });

  test('initialize throws StateError when a JSON asset is missing', () async {
    final _FakeAssetBundle bundle = _FakeAssetBundle(
      strings: const <String, String>{
        requestsKey: '[]',
      },
      errorKeys: const <String>{usersKey},
    );

    expect(
          () => LocalData().initialize(bundle: bundle),
      throwsA(
        isA<StateError>().having(
              (StateError error) => error.message,
          'message',
          contains(usersKey),
        ),
      ),
    );
  });

  test('initialize throws StateError when a JSON asset is empty', () async {
    final _FakeAssetBundle bundle = _FakeAssetBundle(
      strings: const <String, String>{
        usersKey: '   ',
        requestsKey: '[]',
      },
    );

    expect(
          () => LocalData().initialize(bundle: bundle),
      throwsA(
        isA<StateError>().having(
              (StateError error) => error.message,
          'message',
          allOf(
            contains(usersKey),
            contains('vuoto'),
          ),
        ),
      ),
    );
  });

  test('initialize reads JSON when assets are present', () async {
    final _FakeAssetBundle bundle = _FakeAssetBundle(
      strings: const <String, String>{
        usersKey: '[{"uid": "u-1", "email": "a@b.c", "password": "pw", "name": "Name"}]',
        requestsKey: '[]',
      },
    );

    await LocalData().initialize(bundle: bundle);

    expect(LocalData().getAllUsers(), hasLength(1));
  });
}