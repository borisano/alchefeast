require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "responds with HTML content" do
      get :index
      expect(response.content_type).to include("text/html")
    end

    it "handles category parameter" do
      get :index, params: { category: "Italian" }
      expect(response).to be_successful
    end

    it "handles difficulty parameter" do
      get :index, params: { difficulty: "Easy" }
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response for valid recipe id" do
      get :show, params: { id: 1 }
      expect(response).to be_successful
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

    it "responds with HTML content" do
      get :search
      expect(response.content_type).to include("text/html")
    end

    it "handles query parameter" do
      get :search, params: { q: "pasta" }
      expect(response).to be_successful
    end

    it "handles ingredients parameter" do
      get :search, params: { ingredients: "eggs,cheese" }
      expect(response).to be_successful
    end
  end
end
