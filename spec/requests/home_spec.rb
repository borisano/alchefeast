require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "contains expected content" do
      get "/"
      expect(response.body).to include("Alchefeast")
      expect(response.body).to include("What Potion Are We Brewing Today?")
      expect(response.body).to include("Featured Recipes")
    end
  end
end
