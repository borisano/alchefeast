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
    recipe_id = params[:id].to_i

    # Dummy data for individual recipe
    recipes_data = {
      1 => {
        id: 1,
        title: "Classic Spaghetti Carbonara",
        description: "A traditional Italian pasta dish with eggs, cheese, and pancetta. This authentic recipe creates a creamy sauce without using cream, relying instead on eggs and pasta water.",
        image_url: "https://via.placeholder.com/600x400?text=Carbonara",
        prep_time: 15,
        cook_time: 20,
        total_time: 35,
        servings: 4,
        ratings: 4.8,
        category: "Italian",
        difficulty: "Medium",
        ingredients: [
          { name: "Spaghetti", amount: "400g" },
          { name: "Eggs", amount: "4 large" },
          { name: "Pancetta", amount: "150g, diced" },
          { name: "Parmesan Cheese", amount: "100g, grated" },
          { name: "Black Pepper", amount: "freshly ground" },
          { name: "Salt", amount: "to taste" }
        ],
        instructions: [
          "Bring a large pot of salted water to boil for the pasta.",
          "In a large bowl, whisk together eggs, grated Parmesan, and black pepper.",
          "Cook pancetta in a large skillet over medium heat until crispy.",
          "Cook spaghetti according to package directions until al dente.",
          "Reserve 1 cup pasta cooking water before draining.",
          "Add hot pasta to the pancetta skillet and toss.",
          "Remove from heat and quickly stir in egg mixture, adding pasta water as needed.",
          "Serve immediately with extra Parmesan and black pepper."
        ],
        nutrition: {
          calories: 520,
          protein: "24g",
          carbs: "68g",
          fat: "18g"
        },
        tags: [ "Italian", "Pasta", "Quick", "Comfort Food" ]
      },
      2 => {
        id: 2,
        title: "Chicken Tikka Masala",
        description: "Creamy tomato-based curry with tender chicken pieces marinated in yogurt and spices.",
        image_url: "https://via.placeholder.com/600x400?text=Tikka+Masala",
        prep_time: 30,
        cook_time: 40,
        total_time: 70,
        servings: 6,
        ratings: 4.6,
        category: "Indian",
        difficulty: "Hard",
        ingredients: [
          { name: "Chicken Breast", amount: "2 lbs, cubed" },
          { name: "Plain Yogurt", amount: "1 cup" },
          { name: "Tomato Sauce", amount: "2 cups" },
          { name: "Heavy Cream", amount: "1 cup" },
          { name: "Garam Masala", amount: "2 tsp" },
          { name: "Garlic", amount: "6 cloves, minced" },
          { name: "Ginger", amount: "2 tbsp, grated" },
          { name: "Onion", amount: "1 large, diced" }
        ],
        instructions: [
          "Marinate chicken in yogurt and spices for at least 30 minutes.",
          "Cook marinated chicken in a hot skillet until browned.",
          "Sauté onions, garlic, and ginger until fragrant.",
          "Add tomato sauce and simmer for 15 minutes.",
          "Add cooked chicken and cream, simmer until thickened.",
          "Season with garam masala and salt.",
          "Serve with basmati rice and naan bread."
        ],
        nutrition: {
          calories: 380,
          protein: "32g",
          carbs: "12g",
          fat: "22g"
        },
        tags: [ "Indian", "Curry", "Spicy", "Comfort Food" ]
      },
      3 => {
        id: 3,
        title: "Caesar Salad",
        description: "Fresh romaine lettuce with parmesan cheese and croutons in a classic Caesar dressing.",
        image_url: "https://via.placeholder.com/600x400?text=Caesar+Salad",
        prep_time: 10,
        cook_time: 0,
        total_time: 10,
        servings: 2,
        ratings: 4.2,
        category: "Salad",
        difficulty: "Easy",
        ingredients: [
          { name: "Romaine Lettuce", amount: "2 heads, chopped" },
          { name: "Parmesan Cheese", amount: "1/2 cup, grated" },
          { name: "Croutons", amount: "1 cup" },
          { name: "Caesar Dressing", amount: "1/4 cup" },
          { name: "Anchovies", amount: "4 fillets (optional)" },
          { name: "Lemon", amount: "1, juiced" }
        ],
        instructions: [
          "Wash and chop romaine lettuce into bite-sized pieces.",
          "In a large bowl, toss lettuce with Caesar dressing.",
          "Add grated Parmesan cheese and toss again.",
          "Top with croutons and anchovy fillets if using.",
          "Serve immediately while croutons are still crispy."
        ],
        nutrition: {
          calories: 180,
          protein: "8g",
          carbs: "12g",
          fat: "12g"
        },
        tags: [ "Salad", "Quick", "Light", "Vegetarian" ]
      }
    }

    @recipe = recipes_data[recipe_id]

    if @recipe.nil?
      redirect_to recipes_path, alert: "Recipe not found"
    end
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
