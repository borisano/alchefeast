require 'rails_helper'

RSpec.describe "Recipes ask_ai", type: :request do
  describe "POST /recipes/:id/ask_ai" do
    let!(:recipe) { create(:recipe) }

    it "marks recipe as pending and then ready with random text" do
      start = Time.current
      post ask_ai_recipe_path(recipe)
      expect(response).to have_http_status(302).or have_http_status(200)

      recipe.reload
      # Because we simulate delay inline, after the request finishes it should be ready
      expect(recipe.ai_instructions_status).to eq("ready")
      expect(recipe.ai_instructions).to be_present
      expect(recipe.ai_instructions_generated_at).to be >= start
    end

    it "is idempotent if already ready" do
      recipe.update!(ai_instructions_status: :ready, ai_instructions: "Done", ai_instructions_generated_at: Time.current)
      post ask_ai_recipe_path(recipe)
      expect(response).to have_http_status(302).or have_http_status(200)
      expect(recipe.reload.ai_instructions_status).to eq("ready")
    end
  end
end
