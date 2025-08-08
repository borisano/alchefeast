require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  describe "GET /recipes" do
    it "returns http success" do
      get "/recipes"
      expect(response).to have_http_status(:success)
    end

    it "contains expected content" do
      get "/recipes"
      expect(response.body).to include("All Recipes")
      expect(response.body).to include("Filter Recipes")
      expect(response.body).to include("Recipe")
    end
  end

  describe "GET /recipes/:id" do
    let!(:test_recipe) { create(:recipe, title: 'Test Recipe for Request Spec') }

    it "returns http success for valid id" do
      get "/recipes/#{test_recipe.id}"
      expect(response).to have_http_status(:success)
    end

    it "contains recipe details for valid id" do
      get "/recipes/#{test_recipe.id}"
      expect(response.body).to include("Test Recipe for Request Spec")
      expect(response.body).to include("Ingredients")
    end

    it "redirects for invalid id" do
      get "/recipes/999"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/recipes")
    end
  end

  describe "GET /recipes/search" do
    it "returns http success" do
      get "/recipes/search"
      expect(response).to have_http_status(:success)
    end

    it "contains search interface" do
      get "/recipes/search"
      expect(response.body).to include("Search Results")
      expect(response.body).to include("Refine Your Search")
    end

    it "handles search with query parameter" do
      get "/recipes/search", params: { q: "pasta" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("pasta")
    end

    it "handles search with ingredients parameter" do
      get "/recipes/search", params: { ingredients: "eggs,cheese" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("eggs")
      expect(response.body).to include("cheese")
    end

    it "handles navbar search input with comma-separated ingredients" do
      get "/recipes/search", params: { search_input: "eggs,cheese,milk" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("eggs")
      expect(response.body).to include("cheese")
      expect(response.body).to include("milk")
    end

    it "handles navbar search input with single recipe name" do
      get "/recipes/search", params: { search_input: "pasta" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("pasta")
    end

    it "treats comma-separated search_input as ingredient search" do
      # Create test data
      recipe = create(:recipe, title: 'Test Recipe')
      ingredient1 = create(:ingredient, name: 'eggs')
      ingredient2 = create(:ingredient, name: 'cheese')
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient1)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient2)

      get "/recipes/search", params: { search_input: "eggs,cheese" }
      expect(response).to have_http_status(:success)

      # Should show ingredient badges for matching ingredients
      expect(response.body).to include("Matching Ingredients")
    end

    it "treats single search_input as recipe name search" do
      recipe = create(:recipe, title: 'Delicious Pasta Recipe')

      get "/recipes/search", params: { search_input: "pasta" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("pasta")
      expect(response.body).to include(recipe.title)
    end
  end
end
