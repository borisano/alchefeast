require 'rails_helper'

RSpec.describe "Recipes ask_ai", type: :request do
  describe "POST /recipes/:id/ask_ai" do
    let!(:recipe) { create(:recipe) }

    context "with HTML format" do
      it "marks recipe as pending and enqueues job" do
        expect {
          post ask_ai_recipe_path(recipe)
        }.to have_enqueued_job(GenerateAiInstructionsJob).with(recipe.id)

        recipe.reload
        expect(recipe.ai_instructions_status).to eq("pending")
        expect(response).to redirect_to(recipe_path(recipe))
      end

      it "is idempotent if already ready" do
        recipe.update!(ai_instructions_status: :ready, ai_instructions: "Done", ai_instructions_generated_at: Time.current)

        expect {
          post ask_ai_recipe_path(recipe)
        }.not_to have_enqueued_job(GenerateAiInstructionsJob)

        expect(response).to redirect_to(recipe_path(recipe))
        expect(recipe.reload.ai_instructions_status).to eq("ready")
      end

      it "is idempotent if already pending" do
        recipe.update!(ai_instructions_status: :pending)

        expect {
          post ask_ai_recipe_path(recipe)
        }.not_to have_enqueued_job(GenerateAiInstructionsJob)

        expect(response).to redirect_to(recipe_path(recipe))
        expect(recipe.reload.ai_instructions_status).to eq("pending")
      end
    end

    context "with Turbo Stream format" do
      it "marks recipe as pending and returns turbo stream update" do
        expect {
          post ask_ai_recipe_path(recipe), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to have_enqueued_job(GenerateAiInstructionsJob).with(recipe.id)

        recipe.reload
        expect(recipe.ai_instructions_status).to eq("pending")
        expect(response).to have_http_status(200)
        expect(response.content_type).to include("turbo-stream")
        expect(response.body).to include("ai_instructions_recipe_#{recipe.id}")
      end

      it "returns turbo stream for idempotent cases" do
        recipe.update!(ai_instructions_status: :ready, ai_instructions: "Done")

        post ask_ai_recipe_path(recipe), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(200)
        expect(response.content_type).to include("turbo-stream")
      end

      it "includes from_card parameter handling" do
        post ask_ai_recipe_path(recipe, from_card: "1"), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(200)
        expect(response.body).to include("ai_instructions_recipe_#{recipe.id}")
      end
    end

    context "error handling" do
      it "handles non-existent recipe" do
        post ask_ai_recipe_path(id: 99999)
        expect(response).to redirect_to(recipes_path)
        expect(flash[:alert]).to eq("Recipe not found")
      end

      it "handles non-existent recipe with turbo stream" do
        post ask_ai_recipe_path(id: 99999), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(404)
      end
    end
  end
end
