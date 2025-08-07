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
    it "returns http success for valid id" do
      get "/recipes/1"
      expect(response).to have_http_status(:success)
    end

    it "contains recipe details for valid id" do
      get "/recipes/1"
      expect(response.body).to include("Classic Spaghetti Carbonara")
      expect(response.body).to include("Ingredients")
      expect(response.body).to include("Instructions")
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
  end
end
