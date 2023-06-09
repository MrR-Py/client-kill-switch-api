import 'dart:io';

import 'package:client_kill_switch_api/database_controller.dart';
import 'package:client_kill_switch_api/config_controller.dart';
import 'package:client_kill_switch_api/server.dart' as rest;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  print('Starting Client Kill Switch REST Api');
  var config = Config('./data/config.json');
  print('Read config file');

  Database database = Database();
  rest.Server restServer = rest.Server();

  if (await database.init(config.dbAddress.toString(), config.dbPort.toString(),
          config.dbName.toString()) ==
      true) {
    // Use any available host or container IP (usually `0.0.0.0`).
    final ip = InternetAddress.anyIPv4;

    Router? _router = restServer.init(database);

    // Configure a pipeline that logs requests.
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

    // For running in containers, we respect the PORT environment variable.
    final port =
        int.parse(Platform.environment['PORT'] ?? config.serverPort.toString());
    final server = await serve(handler, ip, port);
    print('Server listening on port ${server.port}');
  }
}