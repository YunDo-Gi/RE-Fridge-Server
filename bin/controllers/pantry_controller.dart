import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';

class PantryController {
  final List data = json.decode(File('pantry.json').readAsStringSync());

  getAllIngredients(Request req) {
    // 200: OK
    return Response.ok(json.encode({'success': true, 'data': data}),
        headers: {'Content-Type': 'application/json'});
  }

  getIngredientsByCategory(Request req, String category) {
    final categorizedData =
        data.where((element) => element['category'] == category).toList();

    // 404: Not Found
    if (categorizedData.isEmpty) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Category $category not found'}));
    }
    
    // 200: OK
    else {
      return Response.ok(
          json.encode({'success': true, 'data': categorizedData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getIngredientById(Request req, String ingredientId) {
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = data.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 404: Not Found
    if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      return Response.ok(json.encode({'success': true, 'data': ingredientData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> addIngredient(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredient = json.decode(payload);

    // 400: Bad Request
    if (ingredient['ingredientId'] == null ||
        ingredient['ingredientName'] == null ||
        ingredient['expiryDate'] == null ||
        ingredient['quantity'] == null ||
        ingredient['category'] == null) {
      return Response.badRequest(
          body: json.encode({
            'success': false,
            'error': 'Missing ingredientId, name, category, quantity, or unit'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 409: Conflict
    if (data.any(
        (element) => element['ingredientId'] == ingredient['ingredientId'])) {
      return Response(409,
          body: json.encode({
            'success': false,
            'error': 'Ingredient ${ingredient['ingredientId']} already exists'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 201: Created
    else {
      data.add(ingredient);
      File('pantry.json').writeAsStringSync(json.encode(data));
      return Response(201,
          body: json.encode({'success': true, 'data': ingredient}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> updateIngredient(Request req, String ingredientId) async {
    final payload = await req.readAsString();
    final quantity = json.decode(payload)['quantity'];
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = data.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 400: Bad Request
    if (quantity <= 0) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Quantity must be greater than 0'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 404: Not Found
    else if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      ingredientData['quantity'] = quantity;

      File('pantry.json').writeAsStringSync(json.encode(data));

      return Response.ok(json.encode({'success': true, 'data': ingredientData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> deleteIngredient(Request req, String ingredientId) async {
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = data.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 404: Not Found
    if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      data.remove(ingredientData);

      File('pantry.json').writeAsStringSync(json.encode(data));

      return Response.ok(json.encode({'success': true, 'data': ingredientData}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
