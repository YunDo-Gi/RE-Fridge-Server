import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api/init_api.dart';
import 'db/setup_db.dart';

// Configure routes.
final _router = Router();

void main(List<String> args) async {

  // Initialize database
  print('Initialize database');
  await DBSetup.init();

  // Use any available host or container IP
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');

  // Configure routes
  _router.mount('/', InitApi().handler);
}
