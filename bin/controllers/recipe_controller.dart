import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';

class RecipeController {
  final List data = json.decode(File('recipe.json').readAsStringSync());
  final List pantry = json.decode(File('pantry.json').readAsStringSync());

  getAllRecipes(Request req) {
    // 200: OK
    return Response.ok(json.encode({'success': true, 'data': data}),
        headers: {'Content-Type': 'application/json'});
  }

  getFullfilledRecipes(Request req) async {
    final List ingredients = [];
    for(var ingredient in pantry) {
      ingredients.add(ingredient['ingredientName']);
    }

    // 400: Bad Request
    if (ingredients.isEmpty) {
      return Response.badRequest(
          body: json.encode({'success': false, 'error': 'Missing ingredients'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List fullfilledRecipes = [];
      // Check if recipe contains ingredients
      for (var recipe in data) {
        var count = 0;
        for (var ingredient in recipe['ingredients']) {
          if (ingredients.contains(ingredient)) {
            count++;
          } else {
            continue;
          }
        }
        if (recipe['ingredients'].length / 2 <= count) {
          recipe['fullfillCount'] = count;
          fullfilledRecipes.add(recipe);
        } else {
          continue;
        }
      }

      // Sort recipes by number of fullfilled ingredients

      return Response.ok(
          json.encode({'success': true, 'data': fullfilledRecipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeById(Request req, String recipeId) {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
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
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid recipe data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 409: Conflict
    if (data.any((element) => element['recipeId'] == recipe['recipeId'])) {
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
      return Response(HttpStatus.created,
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
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      data.remove(recipeData);
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
