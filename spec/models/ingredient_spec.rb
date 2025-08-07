require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'associations' do
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:recipes).through(:recipe_ingredients) }
  end

  describe 'validations' do
    subject { build(:ingredient, name: 'test_ingredient') }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'callbacks' do
    describe '#normalize_name' do
      it 'converts name to lowercase' do
        ingredient = create(:ingredient, name: 'FLOUR')
        expect(ingredient.name).to eq('flour')
      end

      it 'strips whitespace' do
        ingredient = create(:ingredient, name: '  sugar  ')
        expect(ingredient.name).to eq('sugar')
      end

      it 'handles mixed case and whitespace' do
        ingredient = create(:ingredient, name: '  All-Purpose FLOUR  ')
        expect(ingredient.name).to eq('all-purpose flour')
      end
    end
  end

  describe 'scopes' do
    describe '.search_by_name' do
      let!(:flour) { create(:ingredient, name: 'all-purpose flour') }
      let!(:sugar) { create(:ingredient, name: 'granulated sugar') }
      let!(:brown_sugar) { create(:ingredient, name: 'brown sugar') }

      it 'finds ingredients by partial name match' do
        results = Ingredient.search_by_name('flour')
        expect(results).to include(flour)
        expect(results).not_to include(sugar, brown_sugar)
      end

      it 'finds multiple ingredients with common term' do
        results = Ingredient.search_by_name('sugar')
        expect(results).to include(sugar, brown_sugar)
        expect(results).not_to include(flour)
      end

      it 'is case insensitive' do
        results = Ingredient.search_by_name('FLOUR')
        expect(results).to include(flour)
      end

      it 'returns empty when no matches' do
        results = Ingredient.search_by_name('chocolate')
        expect(results).to be_empty
      end
    end
  end

  describe 'uniqueness' do
    it 'prevents duplicate ingredients with same name' do
      create(:ingredient, name: 'flour')
      duplicate = build(:ingredient, name: 'flour')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'prevents duplicate ingredients with different case' do
      create(:ingredient, name: 'flour')
      duplicate = build(:ingredient, name: 'FLOUR')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'factory' do
    it 'creates a valid ingredient' do
      ingredient = build(:ingredient)
      expect(ingredient).to be_valid
    end

    it 'creates unique names with sequence' do
      ingredient1 = create(:ingredient)
      ingredient2 = create(:ingredient)
      expect(ingredient1.name).not_to eq(ingredient2.name)
    end

    describe 'traits' do
      it 'creates common ingredients' do
        ingredient = create(:ingredient, :common)
        expect([ 'flour', 'sugar', 'eggs', 'butter', 'milk', 'salt' ]).to include(ingredient.name)
      end

      it 'creates spice ingredients' do
        ingredient = create(:ingredient, :spice)
        expect([ 'salt', 'pepper', 'paprika', 'cumin', 'oregano' ]).to include(ingredient.name)
      end

      it 'creates vegetable ingredients' do
        ingredient = create(:ingredient, :vegetable)
        expect([ 'onions', 'garlic', 'tomatoes', 'carrots', 'potatoes' ]).to include(ingredient.name)
      end

      it 'creates protein ingredients' do
        ingredient = create(:ingredient, :protein)
        expect([ 'chicken breast', 'ground beef', 'eggs', 'cheese' ]).to include(ingredient.name)
      end
    end
  end
end
