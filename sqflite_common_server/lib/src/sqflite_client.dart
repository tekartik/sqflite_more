import 'dart:async';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:pedantic/pedantic.dart';
import 'package:sqflite_common_server/src/constant.dart';
import 'package:sqflite_common_server/src/sqflite_import.dart';
import 'package:sqflite_common_server/src/sqflite_server.dart';
import 'package:tekartik_common_utils/common_utils_import.dart' hide devPrint;
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

class ServerInfo {
  bool? supportsWithoutRowId;
  bool? isIOS;
  bool? isAndroid;
  bool? isMacOS;
  bool? isLinux;
  bool? isWindows;
}

/// Instance of a server
class SqfliteClient {
  SqfliteClient._(this._client, this.serverInfo);

  final json_rpc.Client _client;
  final ServerInfo serverInfo;

  static Future<SqfliteClient> connect(
    String url, {
    WebSocketChannelClientFactory? webSocketChannelClientFactory,
  }) async {
    webSocketChannelClientFactory ??= webSocketChannelClientFactoryIo;
    var webSocketChannel = webSocketChannelClientFactory.connect<String>(url);
    var rpcClient = json_rpc.Client(webSocketChannel);
    ServerInfo _serverInfo;
    unawaited(rpcClient.listen());
    try {
      var serverInfo = await rpcClient.sendRequest(methodGetServerInfo) as Map;
      if (serverInfo[keyName] != serverInfoName) {
        throw 'invalid name in $serverInfo';
      }
      var version = Version.parse(serverInfo[keyVersion] as String);
      if (version < serverInfoMinVersion) {
        throw 'SQFlite server version $version not supported, >=$serverInfoMinVersion expected';
      }
      _serverInfo = ServerInfo()
        ..supportsWithoutRowId = parseBool(serverInfo[keySupportsWithoutRowId])
        ..isIOS = parseBool(serverInfo[keyIsIOS])
        ..isAndroid = parseBool(serverInfo[keyIsAndroid])
        ..isMacOS = parseBool(serverInfo[keyIsMacOS])
        ..isLinux = parseBool(serverInfo[keyIsLinux])
        ..isWindows = parseBool(serverInfo[keyIsWindows]);
    } catch (e) {
      await rpcClient.close();
      rethrow;
    }
    return SqfliteClient._(rpcClient, _serverInfo);
  }

  Future<T> sendRequest<T>(String method, Object? param) async {
    try {
      var result = await _client.sendRequest(method, param);

      if (useNullResponseWorkaround) {
        /// nnbd workaround for issue https://github.com/dart-lang/json_rpc_2/issues/76
        if (result == nullResponseWorkaround) {
          result = null;
        }
      }

      /// Handle workaround
      return result as T;
    } on json_rpc.RpcException catch (e) {
      // devPrint('ERROR ${e.runtimeType} $e ${e.message} ${e.data}');
      throw SqfliteDatabaseException(e.message, e.data);
    }
  }

  static void fixResult<T>(T result) {
    bool shouldFix(Object? value) {
      return value is List && (!(value is Uint8List));
    }

    Uint8List fix(List value) {
      var list = <int?>[];
      for (var item in value) {
        list.add(parseInt(item));
      }
      // devPrint('fix: $value ${value.runtimeType}');
      return Uint8List.fromList(list.cast<int>());
    }

    // devPrint('result1: $result');
    // Convert List to Uint8List
    if (result is List) {
      for (var item in result) {
        if (item is Map) {
          var changed = <String, Object?>{};
          var map = item.cast<String, Object?>();
          map.forEach((String key, Object? value) {
            if (shouldFix(value)) {
              changed[key] = fix(value as List);
            }
          });
          map.addAll(changed);
        }
      }
    } else if (result is Map) {
      // print(result);
      Object? _rows = result['rows'];
      if (_rows is List) {
        var rows = _rows.cast<List>();
        for (var row in rows) {
          for (var i = 0; i < row.length; i++) {
            Object? value = row[i];
            if (shouldFix(value)) {
              row[i] = fix(value as List);
            }
          }
        }
      }
      //col
      //for (var column )
    }
    // devPrint('result2: $result');
  }

  Future<T> invoke<T>(String method, Object? param) async {
    var map = <String, Object?>{keyMethod: method, keyParam: param};
    var result = await sendRequest<T>(methodSqflite, map);

    if (method == methodBatch) {
      if (result is List) {
        for (var line in result) {
          fixResult<Object?>(line);
        }
      }
    } else {
      fixResult(result);
    }
    // return result;

    return result;
  }

  Future close() => _client.close();
}
