import 'package:mysql_client/mysql_client.dart';

// How to print result
// print(result.numOfColumns);
// print(result.numOfRows);
// print(result.lastInsertID);
// print(result.affectedRows);

// print(row.colAt(0));
// print(row.colByName("name"));

// print all rows as Map<String, String>
// print(row.assoc());

class DBSetup {
  static init() async {
    // create connection
    print("Connecting to mysql server...");
    final conn = await MySQLConnection.createConnection(
      host: "localhost",
      port: 3306,
      userName: "root",
      password: "0000",
      databaseName: "refridge",
    );

    try {
      await conn.connect();
      print("Connected");
    } catch (e) {
      print("Exception: $e");
    }
    // close all connections
    await conn.close();
    print("Connection closed");
  }

  Future<MySQLConnection> dbConnector() async {
    // create connection
    print("dbConnector: Connecting to mysql server...");
    final conn = await MySQLConnection.createConnection(
      host: "localhost",
      port: 3306,
      userName: "root",
      password: "0000",
      databaseName: "refridge",
    );

    try {
      await conn.connect();
      print("dbConnector: Connected");
      return conn;
    } catch (e) {
      throw Exception("Exception: $e");
    }
  }

  pantryRef() {}
}
