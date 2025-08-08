require 'rails_helper'

RSpec.describe RecipeImporterService, type: :service do
  let(:service) { described_class.new }
  let(:temp_file) { Tempfile.new([ 'test_recipes', '.json' ]) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    it 'initializes with empty results and errors' do
      expect(service.results[:created_recipes]).to eq(0)
      expect(service.results[:created_ingredients]).to eq(0)
      expect(service.results[:updated_recipes]).to eq(0)
      expect(service.results[:errors]).to eq([])
      expect(service.errors).to eq([])
    end
  end

  describe '#import_from_file' do
    context 'with valid JSON file' do
      let(:valid_recipes) do
        [
          {
            "title" => "Test Recipe 1",
            "cook_time" => 30,
            "prep_time" => 15,
            "ingredients" => [ "1 cup flour", "2 eggs", "1/2 cup milk" ],
            "ratings" => 4.5,
            "cuisine" => "American",
            "category" => "Dessert",
            "author" => "Test Chef",
            "image" => "http://example.com/image.jpg"
          }
        ]
      end

      before do
        temp_file.write(valid_recipes.to_json)
        temp_file.rewind
      end

      it 'successfully imports recipes' do
        expect(service.import_from_file(temp_file.path)).to be true
        expect(service.results[:created_recipes]).to eq(1)
        expect(service.results[:created_ingredients]).to eq(3)
        expect(service.errors).to be_empty
      end

      it 'creates recipe with correct attributes' do
        service.import_from_file(temp_file.path)

        recipe = Recipe.find_by(title: "Test Recipe 1")
        expect(recipe).to be_present
        expect(recipe.cook_time).to eq(30)
        expect(recipe.prep_time).to eq(15)
        expect(recipe.total_time).to eq(45)
        expect(recipe.ratings).to eq(4.5)
        expect(recipe.cuisine).to eq("American")
        expect(recipe.category).to eq("Dessert")
        expect(recipe.author).to eq("Test Chef")
        expect(recipe.image_url).to match(/^https?:\/\//)
      end

      it 'creates associated ingredients' do
        service.import_from_file(temp_file.path)

        recipe = Recipe.find_by(title: "Test Recipe 1")
        ingredient_names = recipe.ingredients.pluck(:name).sort
        expect(ingredient_names).to include("flour", "eggs", "milk")
      end

      it 'creates recipe_ingredients with raw_text' do
        service.import_from_file(temp_file.path)

        recipe = Recipe.find_by(title: "Test Recipe 1")
        raw_texts = recipe.recipe_ingredients.pluck(:raw_text)
        expect(raw_texts).to include("1 cup flour", "2 eggs", "1/2 cup milk")
      end
    end

    context 'with existing recipe' do
      let!(:existing_recipe) { create(:recipe, title: "Test Recipe 1", ratings: 3.0) }
      let(:updated_recipes) do
        [
          {
            "title" => "Test Recipe 1",
            "cook_time" => 25,
            "prep_time" => 10,
            "ingredients" => [ "2 cups flour", "3 eggs" ],
            "ratings" => 4.8,
            "cuisine" => "Italian",
            "category" => "Bread",
            "author" => "Updated Chef",
            "image" => "http://example.com/new-image.jpg"
          }
        ]
      end

      before do
        temp_file.write(updated_recipes.to_json)
        temp_file.rewind
      end

      it 'updates existing recipe' do
        expect(service.import_from_file(temp_file.path)).to be true
        expect(service.results[:updated_recipes]).to eq(1)
        expect(service.results[:created_recipes]).to eq(0)
      end

      it 'updates recipe attributes' do
        service.import_from_file(temp_file.path)

        existing_recipe.reload
        expect(existing_recipe.cook_time).to eq(25)
        expect(existing_recipe.prep_time).to eq(10)
        expect(existing_recipe.ratings).to eq(4.8)
        expect(existing_recipe.cuisine).to eq("Italian")
        expect(existing_recipe.category).to eq("Bread")
        expect(existing_recipe.author).to eq("Updated Chef")
        expect(existing_recipe.image_url).to match(/^https?:\/\//)
      end

      it 'replaces ingredients' do
        # Create initial ingredients
        flour = create(:ingredient, name: "flour")
        eggs = create(:ingredient, name: "eggs")
        create(:recipe_ingredient, recipe: existing_recipe, ingredient: flour, raw_text: "1 cup flour")
        create(:recipe_ingredient, recipe: existing_recipe, ingredient: eggs, raw_text: "1 egg")

        service.import_from_file(temp_file.path)

        existing_recipe.reload
        raw_texts = existing_recipe.recipe_ingredients.pluck(:raw_text)
        expect(raw_texts).to contain_exactly("2 cups flour", "3 eggs")
      end
    end

    context 'with invalid JSON file' do
      before do
        temp_file.write("invalid json content")
        temp_file.rewind
      end

      it 'returns false and adds error' do
        expect(service.import_from_file(temp_file.path)).to be false
        expect(service.errors).to include(match(/Invalid JSON format/))
      end
    end

    context 'with non-existent file' do
      it 'raises ArgumentError' do
        expect {
          service.import_from_file("/non/existent/file.json")
        }.to raise_error(ArgumentError, /File does not exist/)
      end
    end
  end

  describe '#import_recipes' do
    context 'with recipe having parsing errors' do
      let(:recipes_with_errors) do
        [
          { "title" => "Valid Recipe", "ingredients" => [ "1 cup flour" ] },
          { "invalid" => "data" },  # Missing title
          { "title" => "Another Valid Recipe", "ingredients" => [ "2 eggs" ] }
        ]
      end

      it 'continues processing despite errors' do
        service.import_recipes(recipes_with_errors)

        expect(service.results[:created_recipes]).to eq(2)
        expect(service.errors.length).to eq(1)
        expect(service.errors.first).to include("Error importing recipe at index 1")
      end
    end
  end

  describe 'ingredient parsing' do
    context 'with various ingredient formats' do
      let(:complex_recipes) do
        [
          {
            "title" => "Complex Recipe",
            "ingredients" => [
              "1 cup all-purpose flour",
              "2 large eggs",
              "1/2 cup whole milk",
              "1 1/2 teaspoons vanilla extract",
              "3/4 cup packed brown sugar",
              "2 tablespoons unsalted butter, melted",
              "1 (15 ounce) can black beans, drained",
              "Salt and pepper to taste"
            ]
          }
        ]
      end

      before do
        temp_file.write(complex_recipes.to_json)
        temp_file.rewind
      end

      it 'parses ingredients correctly' do
        service.import_from_file(temp_file.path)

        recipe = Recipe.find_by(title: "Complex Recipe")
        ingredient_names = recipe.ingredients.pluck(:name).sort

        expect(ingredient_names).to include(
          "all-purpose flour", "eggs", "milk", "vanilla extract",
          "sugar", "butter, melted", "can black beans, drained", "salt and pepper to taste"
        )
      end

      it 'extracts quantities and units correctly' do
        service.import_from_file(temp_file.path)

        recipe = Recipe.find_by(title: "Complex Recipe")
        recipe_ingredients = recipe.recipe_ingredients.includes(:ingredient)

        flour_ingredient = recipe_ingredients.find { |ri| ri.ingredient.name == "all-purpose flour" }
        expect(flour_ingredient.quantity).to eq(1.0)
        expect(flour_ingredient.unit).to eq("cup")

        vanilla_ingredient = recipe_ingredients.find { |ri| ri.ingredient.name == "vanilla extract" }
        expect(vanilla_ingredient.quantity).to eq(1.5)
        expect(vanilla_ingredient.unit).to eq("teaspoons")

        sugar_ingredient = recipe_ingredients.find { |ri| ri.ingredient.name == "sugar" }
        expect(sugar_ingredient.quantity).to eq(0.75)
        expect(sugar_ingredient.unit).to eq("cup")
      end
    end

    context 'with duplicate ingredients' do
      let!(:existing_ingredient) { create(:ingredient, name: "flour") }

      let(:recipe_with_duplicate) do
        [
          {
            "title" => "Duplicate Ingredient Recipe",
            "ingredients" => [ "1 cup flour", "2 cups all-purpose flour" ]
          }
        ]
      end

      before do
        temp_file.write(recipe_with_duplicate.to_json)
        temp_file.rewind
      end

      it 'reuses existing ingredients' do
        initial_count = Ingredient.count
        service.import_from_file(temp_file.path)

        # Should only create one new ingredient (for the second flour entry that might be parsed differently)
        expect(Ingredient.count).to be <= initial_count + 1
        expect(service.results[:created_ingredients]).to be <= 1
      end
    end
  end

  describe 'edge cases' do
    context 'with empty or nil values' do
      let(:recipes_with_nil_values) do
        [
          {
            "title" => "Minimal Recipe",
            "cook_time" => nil,
            "prep_time" => nil,
            "ingredients" => [ "flour" ],
            "ratings" => nil,
            "cuisine" => "",
            "category" => "",
            "author" => nil,
            "image" => nil
          }
        ]
      end

      before do
        temp_file.write(recipes_with_nil_values.to_json)
        temp_file.rewind
      end

      it 'handles nil and empty values gracefully' do
        expect(service.import_from_file(temp_file.path)).to be true

        recipe = Recipe.find_by(title: "Minimal Recipe")
        expect(recipe.cook_time).to be_nil
        expect(recipe.prep_time).to be_nil
        expect(recipe.ratings).to be_nil
        expect(recipe.cuisine).to be_nil
        expect(recipe.category).to be_nil
        expect(recipe.author).to be_nil
        expect(recipe.image_url).to match(/^https?:\/\//)
      end
    end

    context 'with invalid ingredients array' do
      let(:recipes_with_invalid_ingredients) do
        [
          {
            "title" => "Invalid Ingredients Recipe",
            "ingredients" => "not an array"
          }
        ]
      end

      before do
        temp_file.write(recipes_with_invalid_ingredients.to_json)
        temp_file.rewind
      end

      it 'handles invalid ingredients gracefully' do
        expect(service.import_from_file(temp_file.path)).to be true

        recipe = Recipe.find_by(title: "Invalid Ingredients Recipe")
        expect(recipe.ingredients.count).to eq(0)
      end
    end
  end
end
