require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "responds with HTML content" do
      get :index
      expect(response.content_type).to include("text/html")
    end

    it "has a successful status code" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end
