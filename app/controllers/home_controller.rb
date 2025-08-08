class HomeController < ApplicationController
  def index
    # Get real featured recipes from database
    @featured_recipes = Recipe.limit(3).includes(:ingredients)

    # Get popular ingredients from the database
    @popular_ingredients = Ingredient.joins(:recipe_ingredients)
                                    .group("ingredients.name")
                                    .order("COUNT(recipe_ingredients.id) DESC")
                                    .limit(10)
                                    .pluck(:name)
  end
end
