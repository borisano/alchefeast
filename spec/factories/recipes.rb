FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    cook_time { 20 }
    prep_time { 15 }
    ratings { 4.2 }
    cuisine { "Italian" }
    category { "Main Course" }
    sequence(:author) { |n| "Chef #{n}" }

    trait :quick do
      cook_time { 10 }
      prep_time { 5 }
    end

    trait :slow_cook do
      cook_time { 120 }
      prep_time { 30 }
    end

    trait :highly_rated do
      ratings { 4.8 }
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
          quantity = index + 1  # 1, 2, 3
          unit = [ "cups", "tablespoons", "teaspoons" ][index]  # Deterministic units
          create(:recipe_ingredient,
                 recipe: recipe,
                 ingredient: ingredient,
                 quantity: quantity,
                 unit: unit,
                 raw_text: "#{quantity} #{unit} #{ingredient.name}")
        end
      end
    end
  end
end
