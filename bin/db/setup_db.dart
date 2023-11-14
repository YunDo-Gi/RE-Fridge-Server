import 'package:mysql_client/mysql_client.dart';

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
      var result = await conn.execute('select name from category');

      // print(result.numOfColumns);
      // print(result.numOfRows);
      // print(result.lastInsertID);
      // print(result.affectedRows);
      print(result);
      for (final row in result.rows) {
        // print(row.colAt(0));
        print(row.colByName("name"));

        // print all rows as Map<String, String>
        // print(row.assoc());
      }
    } catch (e) {
      print("Exception: $e");
    }
    // close all connections
    await conn.close();
  }

  Future<void> dbConnector() async {
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
      return await conn.connect();
    } catch (e) {
      print("Exception: $e");
    }

    return await conn.connect();
  }

  pantryRef() {
    
  }
}
