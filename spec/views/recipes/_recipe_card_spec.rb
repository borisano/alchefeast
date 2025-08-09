require "rails_helper"

RSpec.describe "recipes/_recipe_card", type: :view do
  let(:ingredient1) { create(:ingredient, name: "tomatoes") }
  let(:ingredient2) { create(:ingredient, name: "onions") }
  let(:ingredient3) { create(:ingredient, name: "garlic") }
  let(:ingredient4) { create(:ingredient, name: "cheese") }

  let(:recipe) do
    create(:recipe, title: "Test Recipe", category: "Italian", cook_time: 20, prep_time: 10, ratings: 4.5).tap do |r|
      [ ingredient1, ingredient2, ingredient3, ingredient4 ].each_with_index do |ingredient, index|
        create(:recipe_ingredient,
               recipe: r,
               ingredient: ingredient,
               quantity: 1,
               unit: "cup",
               raw_text: "1 cup #{ingredient.name}")
      end
    end
  end

  context "when rendered without search_ingredients" do
    it "displays key ingredients preview" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe }

      expect(rendered).to include("Key Ingredients:")
      expect(rendered).to include("tomatoes")
      expect(rendered).to include("onions")
      expect(rendered).to include("garlic")
      expect(rendered).to include("+1 more")
    end

    it "does not display matching ingredients section" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe }

      expect(rendered).not_to include("Matching Ingredients:")
    end
  end

  context "when rendered with search_ingredients" do
    let(:search_ingredients) { [ "tomatoes", "cheese" ] }

    it "displays matching ingredients" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe, search_ingredients: search_ingredients }

      expect(rendered).to include("Matching Ingredients:")
      expect(rendered).to include("Tomatoes")
      expect(rendered).to include("Cheese")
    end

    it "does not display key ingredients preview" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe, search_ingredients: search_ingredients }

      expect(rendered).not_to include("Key Ingredients:")
    end
  end

  context "common elements" do
    it "displays recipe title and basic information" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe }

      expect(rendered).to include("Test Recipe")
      expect(rendered).to include("Italian")
      expect(rendered).to include("30min")
      expect(rendered).to include("4.5")
      expect(rendered).to include("Quick View")
    end

    it "includes the recipe card structure" do
      render partial: "recipes/recipe_card", locals: { recipe: recipe }

      expect(rendered).to include("class=\"card h-100 shadow-sm recipe-card\"")
      expect(rendered).to include("card-img-top")
      expect(rendered).to include("card-body")
    end
  end
end
