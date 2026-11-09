import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path_provider/path_provider.dart';

class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();
  Future<Database>? _database;
  @visibleForTesting
  void useDatabase(Database database) {
    _database = Future.value(database);
  }

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    DatabaseFactory factory;
    String path = 'seniores-cache.db';
    if (kIsWeb) {
      factory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      path =
          '${(await getApplicationSupportDirectory()).path}/seniores-cache.db';
    } else {
      factory = databaseFactory;
      path = '${await getDatabasesPath()}/seniores-cache.db';
    }
    return factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) => db.execute(
                'CREATE TABLE cache (scope TEXT, key TEXT, value TEXT NOT NULL, PRIMARY KEY(scope,key))')));
  }

  Future<void> put(String scope, String key, dynamic value) async {
    await (await database).insert(
        'cache', {'scope': scope, 'key': key, 'value': jsonEncode(value)},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> get(String scope, String key) async {
    final rows = await (await database).query('cache',
        where: 'scope = ? AND key = ?', whereArgs: [scope, key]);
    return rows.isEmpty ? null : jsonDecode(rows.first['value'] as String);
  }

  Future<void> remove(String scope, String key) async => (await database)
      .delete('cache', where: 'scope = ? AND key = ?', whereArgs: [scope, key]);
  Future<void> clear(String scope) async =>
      (await database).delete('cache', where: 'scope = ?', whereArgs: [scope]);
}
