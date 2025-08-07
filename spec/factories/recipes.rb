FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    cook_time { rand(10..60) }
    prep_time { rand(5..30) }
    ratings { rand(3.0..5.0).round(2) }
    cuisine { ["Italian", "American", "Asian", "French", "Mexican"].sample }
    category { ["Main Course", "Dessert", "Appetizer", "Side Dish", "Breakfast"].sample }
    sequence(:author) { |n| "Chef #{n}" }
    image_url { "https://example.com/recipe_#{id}.jpg" }
    
    trait :quick do
      cook_time { rand(5..15) }
      prep_time { rand(5..10) }
    end
    
    trait :slow_cook do
      cook_time { rand(60..180) }
      prep_time { rand(15..45) }
    end
    
    trait :highly_rated do
      ratings { rand(4.5..5.0).round(2) }
    end
    
    trait :italian do
      cuisine { "Italian" }
      category { "Main Course" }
    end
    
    trait :dessert do
      category { "Dessert" }
      cuisine { "American" }
    end
    
    trait :with_ingredients do
      after(:create) do |recipe|
        ingredients = 3.times.map do |i|
          Ingredient.find_or_create_by(name: "ingredient_for_recipe_#{recipe.id}_#{i}")
        end
        ingredients.each_with_index do |ingredient, index|
          create(:recipe_ingredient, 
                 recipe: recipe, 
                 ingredient: ingredient,
                 quantity: rand(1..5),
                 unit: ["cups", "tablespoons", "teaspoons", "pounds"].sample,
                 raw_text: "#{rand(1..5)} #{["cups", "tablespoons", "teaspoons", "pounds"].sample} #{ingredient.name}")
        end
      end
    end
  end
end
