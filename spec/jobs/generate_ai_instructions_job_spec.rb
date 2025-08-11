require 'rails_helper'

RSpec.describe GenerateAiInstructionsJob, type: :job do
  let!(:recipe) { create(:recipe, ai_instructions_status: :pending) }

  describe "#perform" do
    it "processes pending recipe and updates with AI instructions" do
      recipe = create(:recipe, ai_instructions_status: :pending)
      
      travel_to Time.current do
        expect {
          described_class.perform_now(recipe.id)
        }.to change { recipe.reload.ai_instructions_status }.from("pending").to("ready")
        
        recipe.reload
        expect(recipe.ai_instructions).to be_present
        expect(recipe.ai_instructions).to match(/AI steps: \w+/)
        expect(recipe.ai_instructions_generated_at).to eq(Time.current)
        expect(recipe.ai_instructions_error).to be_nil
      end
    end

    it "skips processing if recipe is not pending" do
      recipe.update!(ai_instructions_status: :ready, ai_instructions: "Already done")
      original_instructions = recipe.ai_instructions

      described_class.perform_now(recipe.id)

      recipe.reload
      expect(recipe.ai_instructions).to eq(original_instructions)
      expect(recipe.ai_instructions_status).to eq("ready")
    end

    it "handles recipe not found gracefully" do
      expect {
        described_class.perform_now(99999)
      }.not_to raise_error
    end

    it "handles errors and marks recipe as failed" do
      allow(SecureRandom).to receive(:hex).and_raise(StandardError.new("Test error"))

      described_class.perform_now(recipe.id)

      recipe.reload
      expect(recipe.ai_instructions_status).to eq("failed")
      expect(recipe.ai_instructions_error).to eq("Test error")
    end

    it "broadcasts turbo stream update when complete" do
      expect {
        described_class.perform_now(recipe.id)
      }.to have_broadcasted_to("recipe_#{recipe.id}")
    end
  end
end
