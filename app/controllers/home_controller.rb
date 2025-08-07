class HomeController < ApplicationController
  def index
    # Dummy data for featured recipes
    @featured_recipes = [
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
        difficulty: "Medium"
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
        difficulty: "Hard"
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
        difficulty: "Easy"
      }
    ]

    # Dummy data for popular ingredients
    @popular_ingredients = [
      "Chicken", "Tomatoes", "Onions", "Garlic", "Olive Oil",
      "Pasta", "Cheese", "Eggs", "Rice", "Potatoes"
    ]
  end
end
