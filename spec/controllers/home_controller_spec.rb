require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "assigns featured recipes" do
      get :index
      expect(assigns(:featured_recipes)).to be_present
      expect(assigns(:featured_recipes)).to be_a(Array)
      expect(assigns(:featured_recipes).length).to eq(3)
    end

    it "assigns popular ingredients" do
      get :index
      expect(assigns(:popular_ingredients)).to be_present
      expect(assigns(:popular_ingredients)).to be_a(Array)
      expect(assigns(:popular_ingredients).length).to eq(10)
    end
  end
end
