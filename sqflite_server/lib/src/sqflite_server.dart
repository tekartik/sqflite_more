import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_server/sqflite_context.dart';
import 'package:sqflite_server/src/constant.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:sqflite/src/sqflite_impl.dart';

int defaultPort = 8501;

/// Web socket server
class SqfliteServer {
  final List<SqfliteServerChannel> _channels = [];
  final WebSocketChannelServer<String> _webSocketChannelServer;

  SqfliteServer._(this._webSocketChannelServer) {
    _webSocketChannelServer.stream.listen((WebSocketChannel<String> channel) {
      _channels.add(SqfliteServerChannel(channel));
    });
  }

  static Future<SqfliteServer> serve(
      {WebSocketChannelServerFactory webSocketChannelServerFactory,
      dynamic address,
      int port}) async {
    webSocketChannelServerFactory ??= webSocketChannelServerFactoryIo;
    var webSocketChannelServer = await webSocketChannelServerFactory
        .serve<String>(address: address, port: port);
    if (webSocketChannelServer != null) {
      return SqfliteServer._(webSocketChannelServer);
    }
    return null;
  }

  Future close() => _webSocketChannelServer.close();

  String get url => _webSocketChannelServer.url;
  int get port => _webSocketChannelServer.port;
}

class SqfliteServerChannel {
  final json_rpc.Server _rpcServer;

  SqfliteServerChannel(WebSocketChannel<String> channel)
      : _rpcServer = json_rpc.Server(channel) {
    // Specific method for getting server info upon start
    _rpcServer.registerMethod(methodGetServerInfo,
        (json_rpc.Parameters parameters) {
      return <String, dynamic>{
        keyName: serverInfoName,
        keyVersion: serverInfoVersion.toString()
      };
    });
    // Specific method for deleting a database
    _rpcServer.registerMethod(methodDeleteDatabase,
        (json_rpc.Parameters parameters) async {
      await databaseFactory
          .deleteDatabase((parameters.value as Map)[keyPath] as String);
      return null;
    });
    // Specific method for creating a directory
    _rpcServer.registerMethod(methodCreateDirectory,
        (json_rpc.Parameters parameters) async {
      var path = await sqfliteContext
          .createDirectory((parameters.value as Map)[keyPath] as String);
      return path;
    });
    // Generic method
    _rpcServer.registerMethod(methodSqflite, (json_rpc.Parameters parameters) {
      var map = parameters.value as Map;
      return invokeMethod<dynamic>(map[keyMethod] as String, map[keyParam]);
    });
    _rpcServer.listen();
  }
}
