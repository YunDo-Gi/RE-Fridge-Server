import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/cart_controller.dart';

final _cartController = CartController();

class CartApi {
  Handler get handler {

    var router = Router();

    // GET: Show all ingredients in shopping list
    router.get('/', _cartController.getAllIngredients);

    // Show specific ingredient in shopping list
    router.get('/ingredient/<ingredientId>', _cartController.getIngredientById);

    // POST: Add ingredient to shopping list
    router.post('/ingredient', _cartController.addIngredient);

    // POST: Add ingredient to pantry
    router.post('/ingredient/<ingredientId>', _cartController.addIngredientToPantry);

    // PATCH: Update ingredient in shopping list
    router.patch('/ingredient/<ingredientId>', _cartController.updateIngredient);

    // DELETE: Delete ingredient from shopping list
    router.delete('/ingredient/<ingredientId>', _cartController.deleteIngredient);

    return router;
  }
}
