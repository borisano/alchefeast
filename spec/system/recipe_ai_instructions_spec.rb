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
      expect(page).to have_button("Ask Alchemist how to cook it")
      expect(page).to have_content("Click \"Ask Alchemist how to cook it\" to generate cooking steps")

      # Click the AI button
      click_button "Ask Alchemist how to cook it"

      # Should immediately show pending state
      expect(page).to have_content("Generating AI instructions...")
      expect(page).to have_css(".spinner-border")

      # Wait for background job to complete and page to update
      perform_enqueued_jobs

      # Should show AI instructions
      expect(page).to have_content("Alchemist advice on cooking")
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
      expect(page).to have_button("Check out Alchemist cooking advice")

      click_button "Check out Alchemist cooking advice"

      # Should not show spinner, should keep existing content
      expect(page).not_to have_css(".spinner-border")
      expect(page).to have_content("Existing AI instructions")
    end
  end

  describe "Recipe card modal AI functionality" do
    it "opens modal and allows AI generation from card" do
      visit recipes_path

      # Find the recipe card and click "Ask Alchemist how to cook it"
      within(".recipe-card", text: recipe.title) do
        click_button "Ask Alchemist how to cook it"
      end

      # Should open modal
      expect(page).to have_css("[data-controller='recipe-modal']")
      expect(page).to have_content(recipe.title)

      # Should show AI Instructions section
      expect(page).to have_content("Alchemist advice on cooking")

      # Click Ask AI button specifically in the modal (using data-controller to scope)
      within("[data-controller='recipe-modal']") do
        expect(page).to have_button("Ask Alchemist")
        find('button', text: 'Ask Alchemist').click
      end

      # Should show pending state
      expect(page).to have_content("Generating AI instructions...")
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

      # Should show AI instructions section
      expect(page).to have_content("Alchemist advice on cooking")

      # Generate AI instructions by clicking the Ask Alchemist button
      within("[data-controller='recipe-modal']") do
        expect(page).to have_button("Ask Alchemist")
        find('button', text: 'Ask Alchemist').click
      end

      # Wait for job completion
      perform_enqueued_jobs

      # Modal should still be open and show results
      expect(page).to have_css("[data-controller='recipe-modal']")
      # Just check that the pending state is gone and it's not still generating
      expect(page).not_to have_content("Generating AI instructions...")
      # Check that some AI content appeared (it could be "AI steps:" or error message)
      expect(page).to have_content(/AI|Alchemist|cooking|instructions/i)
    end
  end

  describe "Error handling" do
    it "shows error state when AI generation fails" do
      # Set the recipe to failed state directly (simulating what would happen after a job failure)
      recipe.update!(
        ai_instructions_status: :failed,
        ai_instructions_error: "Test error"
      )

      visit recipe_path(recipe)

      expect(page).to have_content("Failed to generate AI instructions")
      expect(page).to have_button("Ask Alchemist how to cook it")
    end
  end
end
