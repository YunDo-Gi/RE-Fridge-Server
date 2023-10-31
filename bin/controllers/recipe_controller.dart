import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';

class RecipeController {
  final List data = json.decode(File('recipe.json').readAsStringSync());

  getAllRecipes(Request req) {
    // 200: OK
    return Response.ok(json.encode({'success': true, 'data': data}),
        headers: {'Content-Type': 'application/json'});
  }

  getRecipeById(Request req, String recipeId) {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> addRecipe(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> recipe = json.decode(payload);

    // 400: Bad Request
    if (recipe['recipeId'] == null ||
        recipe['recipeName'] == null ||
        recipe['ingredients'] == null) {
      return Response.badRequest(body: json.encode(
          {'success': false, 'error': 'Invalid recipe data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 409: Conflict
    if (data.any(
        (element) => element['recipeId'] == recipe['recipeId'])) {
      return Response(409,
          body: json.encode({
            'success': false,
            'error': 'Recipe ${recipe['recipeId']} already exists'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 201: Created
    else {
      data.add(recipe);
      return Response(
          HttpStatus.created,
          body: json.encode({'success': true, 'data': recipe}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  deleteRecipe(Request req, String recipeId) {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      data.remove(recipeData);
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}