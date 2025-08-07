FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "ingredient_#{n}" }

    trait :common do
      name { ["flour", "sugar", "eggs", "butter", "milk", "salt"].sample }
    end

    trait :spice do
      name { ["salt", "pepper", "paprika", "cumin", "oregano"].sample }
    end

    trait :vegetable do
      name { ["onions", "garlic", "tomatoes", "carrots", "potatoes"].sample }
    end

    trait :protein do
      name { ["chicken breast", "ground beef", "eggs", "cheese"].sample }
    end
  end
end
