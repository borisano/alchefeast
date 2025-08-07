require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "assigns recipes" do
      get :index
      expect(assigns(:recipes)).to be_present
      expect(assigns(:recipes)).to be_a(Array)
      expect(assigns(:recipes).length).to eq(6)
    end

    it "assigns categories and difficulties" do
      get :index
      expect(assigns(:categories)).to be_present
      expect(assigns(:difficulties)).to be_present
    end

    it "filters recipes by category when provided" do
      get :index, params: { category: "Italian" }
      expect(assigns(:recipes)).to be_present
      italian_recipes = assigns(:recipes).select { |r| r[:category] == "Italian" }
      expect(italian_recipes.length).to eq(assigns(:recipes).length)
    end

    it "filters recipes by difficulty when provided" do
      get :index, params: { difficulty: "Easy" }
      expect(assigns(:recipes)).to be_present
      easy_recipes = assigns(:recipes).select { |r| r[:difficulty] == "Easy" }
      expect(easy_recipes.length).to eq(assigns(:recipes).length)
    end
  end

  describe "GET #show" do
    it "returns a success response for valid recipe id" do
      get :show, params: { id: 1 }
      expect(response).to be_successful
    end

    it "renders the show template for valid recipe id" do
      get :show, params: { id: 1 }
      expect(response).to render_template(:show)
    end

    it "assigns the recipe for valid id" do
      get :show, params: { id: 1 }
      expect(assigns(:recipe)).to be_present
      expect(assigns(:recipe)[:id]).to eq(1)
      expect(assigns(:recipe)[:title]).to eq("Classic Spaghetti Carbonara")
    end

    it "redirects for invalid recipe id" do
      get :show, params: { id: 999 }
      expect(response).to redirect_to(recipes_path)
      expect(flash[:alert]).to eq("Recipe not found")
    end
  end

  describe "GET #search" do
    it "returns a success response" do
      get :search
      expect(response).to be_successful
    end

    it "renders the search template" do
      get :search
      expect(response).to render_template(:search)
    end

    it "assigns search results" do
      get :search, params: { q: "pasta" }
      expect(assigns(:recipes)).to be_present
      expect(assigns(:query)).to eq("pasta")
    end

    it "filters by ingredients when provided" do
      get :search, params: { ingredients: "eggs,cheese" }
      expect(assigns(:ingredients)).to eq(["eggs", "cheese"])
      expect(assigns(:recipes)).to be_present
    end

    it "assigns empty arrays when no search params" do
      get :search
      expect(assigns(:ingredients)).to eq([])
      expect(assigns(:query)).to be_nil
    end
  end
end
