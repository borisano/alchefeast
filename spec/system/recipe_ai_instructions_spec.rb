require 'rails_helper'

RSpec.describe "Recipe AI Instructions Integration", type: :system do
  include ActiveJob::TestHelper

  let!(:recipe) { create(:recipe, :with_ingredients) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "Recipe show page AI functionality" do
    it "allows user to request AI instructions and see live updates" do
      visit recipe_path(recipe)

      expect(page).to have_content(recipe.title)
      expect(page).to have_button("Ask AI how to cook it")
      expect(page).to have_content("Click \"Ask AI how to cook it\" to generate cooking steps")

      # Click the AI button
      click_button "Ask AI how to cook it"

      # Should immediately show pending state
      expect(page).to have_content("Generating AI instructions...")
      expect(page).to have_css(".spinner-border")

      # Wait for background job to complete and page to update
      perform_enqueued_jobs

      # Should show AI instructions
      expect(page).to have_content("AI Cooking Steps")
      expect(page).to have_content("AI steps:")
      expect(page).to have_content("Generated at")
      expect(page).not_to have_css(".spinner-border")
    end

    it "shows idempotent behavior when AI instructions already exist" do
      recipe.update!(
        ai_instructions_status: :ready,
        ai_instructions: "Existing AI instructions",
        ai_instructions_generated_at: 1.hour.ago
      )

      visit recipe_path(recipe)

      expect(page).to have_content("Existing AI instructions")
      expect(page).to have_button("Ask AI how to cook it")

      click_button "Ask AI how to cook it"

      # Should not show spinner, should keep existing content
      expect(page).not_to have_css(".spinner-border")
      expect(page).to have_content("Existing AI instructions")
    end
  end

  describe "Recipe card modal AI functionality" do
    it "opens modal and allows AI generation from card" do
      visit recipes_path

      # Find the recipe card and click "Ask AI how to cook it"
      within(".recipe-card", text: recipe.title) do
        click_button "Ask AI how to cook it"
      end

      # Should open modal
      expect(page).to have_css("[data-controller='recipe-modal']")
      expect(page).to have_content(recipe.title)

      # Should show AI Instructions section
      expect(page).to have_content("AI Cooking Steps")

      # Click Ask AI button in modal header
      within("#ai-instructions-collapse-#{recipe.id}") do
        expect(page).to have_button("Ask AI")
      end

      click_button "Ask AI"

      # Should show pending state
      expect(page).to have_content("Generating...")
      expect(page).to have_css(".spinner-border")

      # Wait for job completion
      perform_enqueued_jobs

      # Should show results in modal
      expect(page).to have_content("AI steps:")
      expect(page).not_to have_css(".spinner-border")
    end

    it "keeps modal open and shows results after AI generation" do
      visit recipes_path

      within(".recipe-card", text: recipe.title) do
        click_link "Quick View"
      end

      # Modal should be open
      expect(page).to have_css("[data-controller='recipe-modal']")

      # AI section should be collapsible and collapsed by default
      expect(page).to have_css("#ai-instructions-collapse-#{recipe.id}.collapse:not(.show)")

      # Click to expand AI section
      click_button "AI Cooking Steps"
      expect(page).to have_css("#ai-instructions-collapse-#{recipe.id}.collapse.show")

      # Generate AI instructions
      click_button "Ask AI"
      perform_enqueued_jobs

      # Modal should still be open and AI section should remain expanded
      expect(page).to have_css("[data-controller='recipe-modal']")
      expect(page).to have_css("#ai-instructions-collapse-#{recipe.id}.collapse.show")
      expect(page).to have_content("AI steps:")
    end
  end

  describe "Error handling" do
    it "shows error state when AI generation fails" do
      # Simulate job failure
      allow_any_instance_of(GenerateAiInstructionsJob).to receive(:perform).and_raise("Test error")

      visit recipe_path(recipe)
      click_button "Ask AI how to cook it"

      perform_enqueued_jobs

      expect(page).to have_content("Failed to generate AI instructions")
      expect(page).to have_content("Error details")
    end
  end
end
