import 'dart:async';

import 'package:sqflite_server/src/constant.dart';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

/// Instance of a server
class SqfliteClient {
  json_rpc.Client _client;

  SqfliteClient._(this._client);

  static Future<SqfliteClient> connect(
    String url, {
    WebSocketChannelClientFactory webSocketChannelClientFactory,
  }) async {
    webSocketChannelClientFactory ??= webSocketChannelClientFactoryIo;
    var webSocketChannel = webSocketChannelClientFactory.connect<String>(url);
    var rpcClient = json_rpc.Client(webSocketChannel);
    rpcClient.listen();
    try {
      var serverInfo = await rpcClient.sendRequest(methodGetServerInfo) as Map;
      if (serverInfo[keyName] != serverInfoName) {
        throw 'invalid name in $serverInfo';
      }
      var version = Version.parse(serverInfo[keyVersion] as String);
      if (version < serverInfoMinVersion) {
        throw 'version $version not support, >=$serverInfoMinVersion expected';
      }
    } catch (e) {
      await rpcClient.close();
      rethrow;
    }
    return SqfliteClient._(rpcClient);
  }

  Future sendRequest(String method, dynamic param) async {
    return await _client.sendRequest(method, param);
  }

  Future<T> invoke<T>(String method, dynamic param) async {
    var map = <String, dynamic>{keyMethod: method, keyParam: param};
    return await sendRequest(methodSqflite, map) as T;
  }

  Future close() => _client.close();
}
