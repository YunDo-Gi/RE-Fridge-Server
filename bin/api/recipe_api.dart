import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/recipe_controller.dart';

final _recipeController = RecipeController();

class PantryApi {
  Handler get handler {

    var router = Router();

    // GET: Show all recipes
    router.get('/', _recipeController.getAllRecipes);

    // Show specific recipe
    router.get('/recipe/<recipeId>', _recipeController.getRecipeById);

    // POST: Add recipe
    router.post('/recipe', _recipeController.addRecipe);

    // DELETE: Delete recipe
    router.delete('/recipe/<recipeId>', _recipeController.deleteRecipe);
        

    return router;
  }
}
