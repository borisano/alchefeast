class RecipesController < ApplicationController
  def index
    # Dummy data for recipes list
    @recipes = [
      {
        id: 1,
        title: "Classic Spaghetti Carbonara",
        description: "A traditional Italian pasta dish with eggs, cheese, and pancetta",
        image_url: "https://via.placeholder.com/300x200?text=Carbonara",
        prep_time: 15,
        cook_time: 20,
        total_time: 35,
        servings: 4,
        ratings: 4.8,
        category: "Italian",
        difficulty: "Medium",
        ingredients: [ "Spaghetti", "Eggs", "Pancetta", "Parmesan Cheese", "Black Pepper" ]
      },
      {
        id: 2,
        title: "Chicken Tikka Masala",
        description: "Creamy tomato-based curry with tender chicken pieces",
        image_url: "https://via.placeholder.com/300x200?text=Tikka+Masala",
        prep_time: 30,
        cook_time: 40,
        total_time: 70,
        servings: 6,
        ratings: 4.6,
        category: "Indian",
        difficulty: "Hard",
        ingredients: [ "Chicken Breast", "Tomatoes", "Heavy Cream", "Garam Masala", "Garlic" ]
      },
      {
        id: 3,
        title: "Caesar Salad",
        description: "Fresh romaine lettuce with parmesan cheese and croutons",
        image_url: "https://via.placeholder.com/300x200?text=Caesar+Salad",
        prep_time: 10,
        cook_time: 0,
        total_time: 10,
        servings: 2,
        ratings: 4.2,
        category: "Salad",
        difficulty: "Easy",
        ingredients: [ "Romaine Lettuce", "Parmesan Cheese", "Croutons", "Caesar Dressing", "Anchovies" ]
      },
      {
        id: 4,
        title: "Beef Stir Fry",
        description: "Quick and easy beef stir fry with mixed vegetables",
        image_url: "https://via.placeholder.com/300x200?text=Beef+Stir+Fry",
        prep_time: 15,
        cook_time: 15,
        total_time: 30,
        servings: 4,
        ratings: 4.4,
        category: "Asian",
        difficulty: "Medium",
        ingredients: [ "Beef Strips", "Bell Peppers", "Broccoli", "Soy Sauce", "Garlic" ]
      },
      {
        id: 5,
        title: "Chocolate Chip Cookies",
        description: "Classic homemade chocolate chip cookies",
        image_url: "https://via.placeholder.com/300x200?text=Cookies",
        prep_time: 20,
        cook_time: 12,
        total_time: 32,
        servings: 24,
        ratings: 4.9,
        category: "Dessert",
        difficulty: "Easy",
        ingredients: [ "Flour", "Butter", "Brown Sugar", "Chocolate Chips", "Vanilla Extract" ]
      },
      {
        id: 6,
        title: "Mushroom Risotto",
        description: "Creamy Italian rice dish with mixed mushrooms",
        image_url: "https://via.placeholder.com/300x200?text=Risotto",
        prep_time: 15,
        cook_time: 25,
        total_time: 40,
        servings: 4,
        ratings: 4.5,
        category: "Italian",
        difficulty: "Hard",
        ingredients: [ "Arborio Rice", "Mixed Mushrooms", "Chicken Stock", "White Wine", "Parmesan" ]
      }
    ]

    # Filter by category if provided
    if params[:category].present?
      @recipes = @recipes.select { |recipe| recipe[:category].downcase == params[:category].downcase }
    end

    # Filter by difficulty if provided
    if params[:difficulty].present?
      @recipes = @recipes.select { |recipe| recipe[:difficulty].downcase == params[:difficulty].downcase }
    end

    @categories = [ "Italian", "Indian", "Salad", "Asian", "Dessert" ]
    @difficulties = [ "Easy", "Medium", "Hard" ]
  end

  def show
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)
  rescue ActiveRecord::RecordNotFound
    redirect_to recipes_path, alert: "Recipe not found"
  end

  def search
    @query = params[:q]
    @ingredients = params[:ingredients]&.split(",")&.map(&:strip) || []

    # Dummy search results
    @recipes = [
      {
        id: 1,
        title: "Classic Spaghetti Carbonara",
        description: "A traditional Italian pasta dish with eggs, cheese, and pancetta",
        image_url: "https://via.placeholder.com/300x200?text=Carbonara",
        prep_time: 15,
        cook_time: 20,
        total_time: 35,
        servings: 4,
        ratings: 4.8,
        category: "Italian",
        difficulty: "Medium",
        matching_ingredients: @ingredients.present? ? @ingredients.select { |ing| [ "eggs", "cheese" ].include?(ing.downcase) } : []
      },
      {
        id: 2,
        title: "Chicken Tikka Masala",
        description: "Creamy tomato-based curry with tender chicken pieces",
        image_url: "https://via.placeholder.com/300x200?text=Tikka+Masala",
        prep_time: 30,
        cook_time: 40,
        total_time: 70,
        servings: 6,
        ratings: 4.6,
        category: "Indian",
        difficulty: "Hard",
        matching_ingredients: @ingredients.present? ? @ingredients.select { |ing| [ "chicken", "tomatoes", "garlic" ].include?(ing.downcase) } : []
      }
    ]

    # Filter by query if provided
    if @query.present?
      @recipes = @recipes.select { |recipe| recipe[:title].downcase.include?(@query.downcase) || recipe[:description].downcase.include?(@query.downcase) }
    end

    # Filter by ingredients if provided
    if @ingredients.present?
      @recipes = @recipes.select { |recipe| recipe[:matching_ingredients].any? }
    end
  end
end
