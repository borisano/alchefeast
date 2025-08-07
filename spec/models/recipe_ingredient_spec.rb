require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  describe 'associations' do
    it { should belong_to(:recipe) }
    it { should belong_to(:ingredient) }
  end

  describe 'validations' do
    let(:recipe) { create(:recipe) }
    let(:ingredient) { create(:ingredient) }

    subject { build(:recipe_ingredient, recipe: recipe, ingredient: ingredient) }

    it { should validate_uniqueness_of(:recipe_id).scoped_to(:ingredient_id) }
    it { should validate_numericality_of(:quantity).is_greater_than(0).allow_nil }
    it { should validate_presence_of(:raw_text) }
  end

  describe 'uniqueness constraint' do
    let(:recipe) { create(:recipe) }
    let(:ingredient) { create(:ingredient) }

    it 'prevents duplicate recipe-ingredient combinations' do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
      duplicate = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:recipe_id]).to include('has already been taken')
    end

    it 'allows same ingredient in different recipes' do
      recipe2 = create(:recipe)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
      second_recipe_ingredient = build(:recipe_ingredient, recipe: recipe2, ingredient: ingredient)

      expect(second_recipe_ingredient).to be_valid
    end

    it 'allows different ingredients in same recipe' do
      ingredient2 = create(:ingredient)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
      second_recipe_ingredient = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient2)

      expect(second_recipe_ingredient).to be_valid
    end
  end

  describe '#scaled_quantity' do
    let(:recipe_ingredient) { create(:recipe_ingredient, quantity: 2.0) }

    it 'scales quantity by given factor' do
      expect(recipe_ingredient.scaled_quantity(2)).to eq(4.0)
      expect(recipe_ingredient.scaled_quantity(0.5)).to eq(1.0)
      expect(recipe_ingredient.scaled_quantity(1.5)).to eq(3.0)
    end

    it 'returns nil when quantity is nil' do
      recipe_ingredient.quantity = nil
      expect(recipe_ingredient.scaled_quantity(2)).to be_nil
    end

    it 'handles decimal scaling' do
      recipe_ingredient.quantity = 1.5
      expect(recipe_ingredient.scaled_quantity(2.5)).to eq(3.75)
    end
  end

  describe '#display_text' do
    let(:ingredient) { create(:ingredient, name: 'flour') }
    let(:recipe_ingredient) do
      create(:recipe_ingredient,
             ingredient: ingredient,
             quantity: 2.0,
             unit: 'cups',
             raw_text: '2 cups all-purpose flour')
    end

    it 'returns raw_text when scale_factor is 1' do
      expect(recipe_ingredient.display_text(1)).to eq('2 cups all-purpose flour')
    end

    it 'returns raw_text when scale_factor is not provided' do
      expect(recipe_ingredient.display_text).to eq('2 cups all-purpose flour')
    end

    it 'returns scaled text when scale_factor is not 1 and quantity/unit are present' do
      expect(recipe_ingredient.display_text(2)).to eq('4.0 cups flour')
    end

    it 'returns raw_text when quantity is nil' do
      recipe_ingredient.quantity = nil
      expect(recipe_ingredient.display_text(2)).to eq('2 cups all-purpose flour')
    end

    it 'returns raw_text when unit is nil' do
      recipe_ingredient.unit = nil
      expect(recipe_ingredient.display_text(2)).to eq('2 cups all-purpose flour')
    end

    it 'handles fractional scaling' do
      expect(recipe_ingredient.display_text(0.5)).to eq('1.0 cups flour')
    end
  end

  describe 'factory' do
    it 'creates a valid recipe_ingredient' do
      recipe_ingredient = build(:recipe_ingredient)
      expect(recipe_ingredient).to be_valid
    end

    it 'creates associated recipe and ingredient' do
      recipe_ingredient = create(:recipe_ingredient)
      expect(recipe_ingredient.recipe).to be_present
      expect(recipe_ingredient.ingredient).to be_present
    end

    describe 'traits' do
      it 'creates measured quantities' do
        ri = create(:recipe_ingredient, :measured)
        expect([ 0.25, 0.5, 0.75, 1, 1.5, 2, 3 ]).to include(ri.quantity)
        expect([ 'cups', 'tablespoons', 'teaspoons' ]).to include(ri.unit)
      end

      it 'creates whole item quantities' do
        ri = create(:recipe_ingredient, :whole_items)
        expect(ri.quantity).to be_between(1, 6)
        expect([ 'large', 'medium', 'small', 'whole' ]).to include(ri.unit)
      end

      it 'creates weight-based quantities' do
        ri = create(:recipe_ingredient, :weight_based)
        expect(ri.quantity).to be_between(1, 3)
        expect([ 'pounds', 'ounces', 'grams' ]).to include(ri.unit)
      end
    end
  end
end
