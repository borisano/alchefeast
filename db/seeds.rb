# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data in development
if Rails.env.development?
  RecipeIngredient.destroy_all
  Recipe.destroy_all
  Ingredient.destroy_all
end

# Create base ingredients
ingredients_data = [
  "all-purpose flour",
  "sugar",
  "eggs",
  "butter",
  "milk",
  "salt",
  "baking powder",
  "vanilla extract",
  "olive oil",
  "onions",
  "garlic",
  "tomatoes",
  "chicken breast",
  "ground beef",
  "rice",
  "pasta",
  "cheese",
  "bell peppers",
  "carrots",
  "potatoes"
]

puts "Creating ingredients..."
ingredients = ingredients_data.map do |name|
  Ingredient.find_or_create_by!(name: name.downcase)
end
puts "Created #{ingredients.count} ingredients"

# Create sample recipes
recipes_data = [
  {
    title: "Classic Chocolate Chip Cookies",
    cook_time: 12,
    prep_time: 15,
    ratings: 4.8,
    cuisine: "American",
    category: "Dessert",
    author: "Jane Baker",
    image_url: "https://example.com/cookies.jpg",
    ingredients: [
      { name: "all-purpose flour", quantity: 2.25, unit: "cups", raw_text: "2¼ cups all-purpose flour" },
      { name: "sugar", quantity: 0.75, unit: "cup", raw_text: "¾ cup granulated sugar" },
      { name: "butter", quantity: 1, unit: "cup", raw_text: "1 cup softened butter" },
      { name: "eggs", quantity: 2, unit: "large", raw_text: "2 large eggs" },
      { name: "vanilla extract", quantity: 2, unit: "teaspoons", raw_text: "2 teaspoons vanilla extract" }
    ]
  },
  {
    title: "Simple Tomato Pasta",
    cook_time: 20,
    prep_time: 10,
    ratings: 4.5,
    cuisine: "Italian",
    category: "Main Course",
    author: "Mario Chef",
    image_url: "https://example.com/pasta.jpg",
    ingredients: [
      { name: "pasta", quantity: 1, unit: "pound", raw_text: "1 lb pasta" },
      { name: "tomatoes", quantity: 4, unit: "large", raw_text: "4 large tomatoes, diced" },
      { name: "garlic", quantity: 3, unit: "cloves", raw_text: "3 cloves garlic, minced" },
      { name: "olive oil", quantity: 3, unit: "tablespoons", raw_text: "3 tablespoons olive oil" },
      { name: "salt", quantity: 1, unit: "teaspoon", raw_text: "1 teaspoon salt" }
    ]
  },
  {
    title: "Fluffy Pancakes",
    cook_time: 15,
    prep_time: 10,
    ratings: 4.7,
    cuisine: "American",
    category: "Breakfast",
    author: "Morning Glory",
    image_url: "https://example.com/pancakes.jpg",
    ingredients: [
      { name: "all-purpose flour", quantity: 2, unit: "cups", raw_text: "2 cups all-purpose flour" },
      { name: "milk", quantity: 1.75, unit: "cups", raw_text: "1¾ cups milk" },
      { name: "eggs", quantity: 2, unit: "large", raw_text: "2 large eggs" },
      { name: "sugar", quantity: 2, unit: "tablespoons", raw_text: "2 tablespoons sugar" },
      { name: "baking powder", quantity: 2, unit: "teaspoons", raw_text: "2 teaspoons baking powder" }
    ]
  },
  {
    title: "Chicken Stir Fry",
    cook_time: 15,
    prep_time: 20,
    ratings: 4.6,
    cuisine: "Asian",
    category: "Main Course",
    author: "Wok Master",
    image_url: "https://example.com/stirfry.jpg",
    ingredients: [
      { name: "chicken breast", quantity: 1, unit: "pound", raw_text: "1 lb chicken breast, sliced" },
      { name: "bell peppers", quantity: 2, unit: "large", raw_text: "2 large bell peppers, sliced" },
      { name: "onions", quantity: 1, unit: "medium", raw_text: "1 medium onion, sliced" },
      { name: "garlic", quantity: 2, unit: "cloves", raw_text: "2 cloves garlic, minced" },
      { name: "olive oil", quantity: 2, unit: "tablespoons", raw_text: "2 tablespoons olive oil" }
    ]
  },
  {
    title: "Beef and Rice Bowl",
    cook_time: 25,
    prep_time: 15,
    ratings: 4.4,
    cuisine: "Asian",
    category: "Main Course",
    author: "Rice King",
    image_url: "https://example.com/ricebowl.jpg",
    ingredients: [
      { name: "ground beef", quantity: 1, unit: "pound", raw_text: "1 lb ground beef" },
      { name: "rice", quantity: 2, unit: "cups", raw_text: "2 cups jasmine rice" },
      { name: "onions", quantity: 1, unit: "medium", raw_text: "1 medium onion, diced" },
      { name: "garlic", quantity: 3, unit: "cloves", raw_text: "3 cloves garlic, minced" },
      { name: "carrots", quantity: 2, unit: "medium", raw_text: "2 medium carrots, diced" }
    ]
  },
  {
    title: "Cheesy Potato Gratin",
    cook_time: 45,
    prep_time: 20,
    ratings: 4.9,
    cuisine: "French",
    category: "Side Dish",
    author: "French Cook",
    image_url: "https://example.com/gratin.jpg",
    ingredients: [
      { name: "potatoes", quantity: 3, unit: "pounds", raw_text: "3 lbs potatoes, thinly sliced" },
      { name: "cheese", quantity: 2, unit: "cups", raw_text: "2 cups grated cheese" },
      { name: "milk", quantity: 2, unit: "cups", raw_text: "2 cups whole milk" },
      { name: "butter", quantity: 3, unit: "tablespoons", raw_text: "3 tablespoons butter" },
      { name: "salt", quantity: 1, unit: "teaspoon", raw_text: "1 teaspoon salt" }
    ]
  }
]

puts "Creating recipes with ingredients..."
recipes_data.each do |recipe_data|
  recipe = Recipe.find_or_create_by!(title: recipe_data[:title]) do |r|
    r.cook_time = recipe_data[:cook_time]
    r.prep_time = recipe_data[:prep_time]
    r.ratings = recipe_data[:ratings]
    r.cuisine = recipe_data[:cuisine]
    r.category = recipe_data[:category]
    r.author = recipe_data[:author]
    r.image_url = recipe_data[:image_url]
  end

  recipe_data[:ingredients].each do |ingredient_data|
    ingredient = Ingredient.find_by!(name: ingredient_data[:name])
    RecipeIngredient.find_or_create_by!(
      recipe: recipe,
      ingredient: ingredient
    ) do |ri|
      ri.quantity = ingredient_data[:quantity]
      ri.unit = ingredient_data[:unit]
      ri.raw_text = ingredient_data[:raw_text]
    end
  end

  puts "Created recipe: #{recipe.title}"
end

puts "\nSeed data creation completed!"
puts "Created #{Recipe.count} recipes"
puts "Created #{Ingredient.count} ingredients"
puts "Created #{RecipeIngredient.count} recipe-ingredient relationships"
