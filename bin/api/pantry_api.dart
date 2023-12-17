import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/pantry_controller.dart';

final _pantryController = PantryController();

class PantryApi {
  Handler get handler {
    var router = Router();

    // GET: Show all ingredients in pantry
    router.get('/', _pantryController.getAllIngredients);

    // GET: Show specific category in pantry
    router.get('/<category>', _pantryController.getIngredientsByCategory);

    // GET: Show specific ingredient information in pantry
    router.get(
        '/ingredient/<ingredientId>', _pantryController.getIngredientById);

    // POST: Add ingredient to pantry
    router.post('/', _pantryController.addIngredients);

    // POST: Add ingredient to shopping list
    router.post('/<ingredientId>', _pantryController.addIngredientToCart);

    // PATCH: Update ingredient in pantry
    router.patch('/<ingredientId>', _pantryController.updateIngredient);

    // DELETE: Delete ingredient from pantry
    router.delete('/<ingredientId>', _pantryController.deleteIngredient);

    return router;
  }
}