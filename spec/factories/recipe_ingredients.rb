FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    quantity { rand(1..5).to_f }
    unit { [ "cups", "tablespoons", "teaspoons", "pounds", "ounces", "cloves" ].sample }

    # Set raw_text after other attributes are set, but only if not already set
    after(:build) do |recipe_ingredient|
      if recipe_ingredient.raw_text.blank?
        recipe_ingredient.raw_text = "#{recipe_ingredient.quantity} #{recipe_ingredient.unit} #{recipe_ingredient.ingredient&.name || 'ingredient'}"
      end
    end

    trait :measured do
      quantity { [ 0.25, 0.5, 0.75, 1, 1.5, 2, 3 ].sample }
      unit { [ "cups", "tablespoons", "teaspoons" ].sample }
    end

    trait :whole_items do
      quantity { rand(1..6) }
      unit { [ "large", "medium", "small", "whole" ].sample }
    end

    trait :weight_based do
      quantity { rand(1..3) }
      unit { [ "pounds", "ounces", "grams" ].sample }
    end
  end
end
