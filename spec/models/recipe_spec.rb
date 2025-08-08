require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe 'associations' do
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:ingredients).through(:recipe_ingredients) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_numericality_of(:ratings).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5).allow_nil }
    it { should validate_numericality_of(:cook_time).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:prep_time).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'callbacks' do
    describe '#calculate_total_time' do
      it 'calculates total_time from cook_time and prep_time' do
        recipe = build(:recipe, cook_time: 30, prep_time: 15)
        recipe.save
        expect(recipe.total_time).to eq(45)
      end

      it 'handles nil cook_time' do
        recipe = build(:recipe, cook_time: nil, prep_time: 15)
        recipe.save
        expect(recipe.total_time).to eq(15)
      end

      it 'handles nil prep_time' do
        recipe = build(:recipe, cook_time: 30, prep_time: nil)
        recipe.save
        expect(recipe.total_time).to eq(30)
      end

      it 'handles both nil times' do
        recipe = build(:recipe, cook_time: nil, prep_time: nil)
        recipe.save
        expect(recipe.total_time).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:italian_recipe) { create(:recipe, cuisine: 'Italian') }
    let!(:american_recipe) { create(:recipe, cuisine: 'American') }
    let!(:quick_recipe) { create(:recipe, cook_time: 10, prep_time: 5) }
    let!(:slow_recipe) { create(:recipe, cook_time: 60, prep_time: 30) }
    let!(:highly_rated) { create(:recipe, ratings: 4.8) }
    let!(:low_rated) { create(:recipe, ratings: 3.2) }

    describe '.by_category' do
      let!(:dessert) { create(:recipe, category: 'Dessert') }
      let!(:main_course) { create(:recipe, category: 'Main Course') }

      it 'filters by category' do
        expect(Recipe.by_category('Dessert')).to include(dessert)
        expect(Recipe.by_category('Dessert')).not_to include(main_course)
      end

      it 'returns all recipes when category is blank' do
        expect(Recipe.by_category('')).to eq(Recipe.all)
      end
    end

    describe '.by_cuisine' do
      it 'filters by cuisine' do
        expect(Recipe.by_cuisine('Italian')).to include(italian_recipe)
        expect(Recipe.by_cuisine('Italian')).not_to include(american_recipe)
      end
    end

    describe '.by_max_time' do
      it 'filters by maximum total time' do
        expect(Recipe.by_max_time(20)).to include(quick_recipe)
        expect(Recipe.by_max_time(20)).not_to include(slow_recipe)
      end
    end

    describe '.by_min_rating' do
      it 'filters by minimum rating' do
        expect(Recipe.by_min_rating(4.0)).to include(highly_rated)
        expect(Recipe.by_min_rating(4.0)).not_to include(low_rated)
      end
    end

    describe '.with_ingredients' do
      let!(:flour) { create(:ingredient, name: 'flour') }
      let!(:sugar) { create(:ingredient, name: 'sugar') }
      let!(:eggs) { create(:ingredient, name: 'eggs') }
      let!(:vanilla) { create(:ingredient, name: 'vanilla extract') }

      let!(:recipe_with_flour_sugar) do
        recipe = create(:recipe, title: 'Cookies')
        create(:recipe_ingredient, recipe: recipe, ingredient: flour)
        create(:recipe_ingredient, recipe: recipe, ingredient: sugar)
        recipe
      end

      let!(:recipe_with_all_three) do
        recipe = create(:recipe, title: 'Cake')
        create(:recipe_ingredient, recipe: recipe, ingredient: flour)
        create(:recipe_ingredient, recipe: recipe, ingredient: sugar)
        create(:recipe_ingredient, recipe: recipe, ingredient: eggs)
        recipe
      end

      let!(:recipe_with_only_flour) do
        recipe = create(:recipe, title: 'Bread')
        create(:recipe_ingredient, recipe: recipe, ingredient: flour)
        recipe
      end

      it 'finds recipes with all specified ingredients' do
        results = Recipe.with_ingredients([ 'flour', 'sugar' ])
        expect(results).to include(recipe_with_flour_sugar, recipe_with_all_three)
        expect(results).not_to include(recipe_with_only_flour)
      end

      it 'does not include recipes missing any ingredient' do
        results = Recipe.with_ingredients([ 'flour', 'sugar', 'eggs' ])
        expect(results).to include(recipe_with_all_three)
        expect(results).not_to include(recipe_with_flour_sugar, recipe_with_only_flour)
      end

      it 'handles case-insensitive matching' do
        results = Recipe.with_ingredients([ 'FLOUR', 'SUGAR' ])
        expect(results).to include(recipe_with_flour_sugar, recipe_with_all_three)
      end

      it 'handles single ingredient search' do
        results = Recipe.with_ingredients([ 'flour' ])
        expect(results).to include(recipe_with_flour_sugar, recipe_with_all_three, recipe_with_only_flour)
      end

      it 'returns empty for non-existent ingredients' do
        results = Recipe.with_ingredients([ 'non-existent-ingredient' ])
        expect(results).to be_empty
      end

      it 'returns none for blank input' do
        expect(Recipe.with_ingredients([])).to eq(Recipe.none)
        expect(Recipe.with_ingredients(nil)).to eq(Recipe.none)
      end
    end

    describe '.with_any_ingredients' do
      let!(:flour) { create(:ingredient, name: 'flour') }
      let!(:sugar) { create(:ingredient, name: 'sugar') }
      let!(:chocolate) { create(:ingredient, name: 'chocolate chips') }

      let!(:recipe_with_flour) do
        recipe = create(:recipe, title: 'Bread')
        create(:recipe_ingredient, recipe: recipe, ingredient: flour)
        recipe
      end

      let!(:recipe_with_sugar) do
        recipe = create(:recipe, title: 'Candy')
        create(:recipe_ingredient, recipe: recipe, ingredient: sugar)
        recipe
      end

      let!(:recipe_with_chocolate) do
        recipe = create(:recipe, title: 'Cookies')
        create(:recipe_ingredient, recipe: recipe, ingredient: chocolate)
        recipe
      end

      let!(:recipe_without_any) do
        vanilla = create(:ingredient, name: 'vanilla')
        recipe = create(:recipe, title: 'Pudding')
        create(:recipe_ingredient, recipe: recipe, ingredient: vanilla)
        recipe
      end

      it 'finds recipes with any of the specified ingredients' do
        results = Recipe.with_any_ingredients([ 'flour', 'sugar' ])
        expect(results).to include(recipe_with_flour, recipe_with_sugar)
        expect(results).not_to include(recipe_with_chocolate, recipe_without_any)
      end

      it 'finds all recipes when they each have different specified ingredients' do
        results = Recipe.with_any_ingredients([ 'flour', 'sugar', 'chocolate chips' ])
        expect(results).to include(recipe_with_flour, recipe_with_sugar, recipe_with_chocolate)
        expect(results).not_to include(recipe_without_any)
      end

      it 'handles case-insensitive matching' do
        results = Recipe.with_any_ingredients([ 'FLOUR' ])
        expect(results).to include(recipe_with_flour)
      end

      it 'returns empty for non-existent ingredients' do
        results = Recipe.with_any_ingredients([ 'non-existent-ingredient' ])
        expect(results).to be_empty
      end

      it 'returns none for blank input' do
        expect(Recipe.with_any_ingredients([])).to eq(Recipe.none)
        expect(Recipe.with_any_ingredients(nil)).to eq(Recipe.none)
      end

      it 'handles single ingredient search' do
        results = Recipe.with_any_ingredients([ 'flour' ])
        expect(results).to include(recipe_with_flour)
        expect(results).not_to include(recipe_with_sugar, recipe_with_chocolate)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid recipe' do
      recipe = build(:recipe)
      expect(recipe).to be_valid
    end

    it 'creates a recipe with ingredients using trait' do
      recipe = create(:recipe, :with_ingredients)
      expect(recipe.ingredients.count).to eq(3)
      expect(recipe.recipe_ingredients.count).to eq(3)
    end
  end
end
