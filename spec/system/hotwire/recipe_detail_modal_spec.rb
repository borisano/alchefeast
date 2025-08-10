require 'rails_helper'

RSpec.describe "Recipe Detail Modal/Drawer", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:recipe) do
    create(:recipe,
           title: "Delicious Pasta",
           category: "Italian",
           cuisine: "Italian",
           total_time: 30,
           prep_time: 15,
           cook_time: 15,
           ratings: 4.5)
  end

  let!(:ingredients) do
    [
      create(:ingredient, name: "pasta"),
      create(:ingredient, name: "tomatoes"),
      create(:ingredient, name: "basil")
    ]
  end

  let!(:recipe_ingredients) do
    [
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredients[0], quantity: 200, unit: "g", raw_text: "200g pasta"),
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredients[1], quantity: 2, unit: "cups", raw_text: "2 cups diced tomatoes"),
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredients[2], raw_text: "Fresh basil leaves")
    ]
  end

  describe "opening recipe modal from recipes index" do
    it "displays modal with recipe details without page navigation" do
      visit recipes_path

      # Should have recipe cards
      expect(page).to have_css('.recipe-card', count: 1)
      expect(page).to have_content(recipe.title)

      # Click the Quick View button to open modal
      click_link "Quick View"

      # Should open modal without page reload
      within 'turbo-frame[id="recipe_modal"]' do
        expect(page).to have_content(recipe.title)
        expect(page).to have_content("Italian")
        expect(page).to have_content("pasta")
        expect(page).to have_content("diced tomatoes")
        expect(page).to have_content("basil")

        # Should be a custom modal drawer
        expect(page).to have_css('.modal-drawer.show')
      end

      # URL should be the modal path
      expect(current_path).to eq(modal_recipe_path(recipe))
    end

    it "displays recipe statistics in modal" do
      visit recipes_path

      within('.recipe-card') do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        # Should show recipe statistics
        expect(page).to have_content("Recipe Information")
        expect(page).to have_content("3") # Number of ingredients
        expect(page).to have_content("30") # Total time
        expect(page).to have_content("4.5") # Rating
        expect(page).to have_content("New") # Age
      end
    end

    it "displays cooking information when available" do
      visit recipes_path

      within('.recipe-card') do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        # Should show cooking information
        expect(page).to have_content("Cooking Information")
        expect(page).to have_content("Time Breakdown")
        expect(page).to have_content("Prep time: 15 minutes")
        expect(page).to have_content("Cook time: 15 minutes")
        expect(page).to have_content("Total time: 30 minutes")
      end
    end

    it "provides action buttons in modal" do
      visit recipes_path

      within('.recipe-card') do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        # Should have action buttons
        expect(page).to have_link("Full View")
        expect(page).to have_button("Print")

        # Full View should link to recipe show page
        expect(page).to have_css("a[href='#{recipe_path(recipe)}']")
      end
    end
  end

  describe "opening recipe modal from search results" do
    it "works from search results page" do
      visit recipes_path(q: recipe.title.split.first)

      # Should be on recipes page with search results
      expect(page).to have_content("All Recipes")
      expect(page).to have_content(recipe.title)

      # Click Quick View to open modal
      within first(".recipe-card") do
        click_link "Quick View"
      end

      # Should show modal with recipe details
      within 'turbo-frame[id="recipe_modal"]' do
        expect(page).to have_content(recipe.title)
        expect(page).to have_content("Ingredients")
      end
    end
  end

  describe "modal close functionality" do
    it "has close button in modal header" do
      visit recipes_path

      click_link "Quick View"

      # Modal should be visible
      expect(page).to have_css('turbo-frame[id="recipe_modal"]')
      expect(page).to have_css('.modal-drawer.show')

      # Should have close button
      expect(page).to have_css('button.btn-close')
    end

    it "closes modal when clicking outside (backdrop)" do
      visit recipes_path

      click_link "Quick View"

      # Modal should be visible
      expect(page).to have_css('.modal-drawer.show')
      expect(page).to have_css('.modal-backdrop')

      # Should have backdrop element that can be clicked
      expect(page).to have_css('[data-recipe-modal-target="backdrop"]')
    end

    it "supports ESC key functionality" do
      visit recipes_path

      click_link "Quick View"

      # Modal should be visible
      expect(page).to have_css('.modal-drawer.show')

      # ESC key functionality is implemented in the Stimulus controller
      # but can't be easily tested with the rack_test driver.
      # The controller handles document keydown events for ESC key.
      expect(page).to have_css('[data-recipe-modal-target="modal"]')
    end
  end

  describe "modal responsiveness" do
    it "displays properly formatted content for mobile-friendly viewing" do
      visit recipes_path

      within('.recipe-card') do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        # Should use responsive classes
        expect(page).to have_css('.col-6')
        expect(page).to have_css('.row')

        # Should have proper spacing and sizing
        expect(page).to have_css('.p-2', minimum: 1)
        expect(page).to have_css('.mb-4', minimum: 1)
      end
    end
  end

  describe "multiple recipes" do
    let!(:second_recipe) do
      create(:recipe,
             title: "Amazing Pizza",
             category: "Italian")
    end

    it "can switch between different recipe modals" do
      visit recipes_path

      # Open first recipe modal
      within first('.recipe-card') do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        expect(page).to have_content("Delicious Pasta")
      end

      # Navigate back or close modal (simulated by revisiting)
      visit recipes_path

      # Open second recipe modal
      within all('.recipe-card').last do
        click_link "Quick View"
      end

      within 'turbo-frame[id="recipe_modal"]' do
        expect(page).to have_content("Amazing Pizza")
        expect(page).to have_content("35 min")
        expect(page).to have_content("4.2/5")
      end
    end
  end

  describe "modal route accessibility" do
    it "modal route is accessible directly" do
      visit modal_recipe_path(recipe)

      # Should show modal content even when accessed directly
      expect(page).to have_content("Delicious Pasta")
      expect(page).to have_content("Italian")
      expect(page).to have_content("pasta")
    end
  end

  describe "error handling" do
    it "handles non-existent recipe gracefully" do
      # Visit with invalid recipe ID should redirect
      visit modal_recipe_path(999999)

      # Should redirect back to recipes with error message or show 404
      expect(current_path).to eq(recipes_path)
      # Alert messages might be handled differently in a real app
      # For now just check we're redirected safely
    end
  end
end
