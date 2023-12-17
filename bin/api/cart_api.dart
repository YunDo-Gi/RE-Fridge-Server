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
    router.get('/<cartId>', _cartController.getIngredientById);

    // POST: Add ingredient to shopping list
    router.post('/', _cartController.addIngredients);

    // POST: Add ingredient to pantry
    router.post('/<cartId>', _cartController.addIngredientToPantry);

    // PATCH: Update ingredient in shopping list
    router.patch('/<cartId>', _cartController.updateIngredient);

    // DELETE: Delete ingredient from shopping list
    router.delete('/<cartId>', _cartController.deleteIngredient);

    return router;
  }
}