FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    quantity { rand(1..5).to_f }
    unit { ["cups", "tablespoons", "teaspoons", "pounds", "ounces", "cloves"].sample }
    raw_text { "#{quantity} #{unit} #{ingredient&.name || 'ingredient'}" }
    
    trait :measured do
      quantity { [0.25, 0.5, 0.75, 1, 1.5, 2, 3].sample }
      unit { ["cups", "tablespoons", "teaspoons"].sample }
    end
    
    trait :whole_items do
      quantity { rand(1..6) }
      unit { ["large", "medium", "small", "whole"].sample }
    end
    
    trait :weight_based do
      quantity { rand(1..3) }
      unit { ["pounds", "ounces", "grams"].sample }
    end
  end
end
