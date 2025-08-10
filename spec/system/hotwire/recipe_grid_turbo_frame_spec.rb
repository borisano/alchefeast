require 'rails_helper'

RSpec.describe "Recipe Grid Turbo Frame", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:recipe1) { create(:recipe, title: "Chicken Pasta", category: "Italian") }
  let!(:recipe2) { create(:recipe, title: "Beef Tacos", category: "Mexican") }
  let!(:recipe3) { create(:recipe, title: "Caesar Salad", category: "Italian") }

  describe "filtering with Turbo Frames" do
    it "updates recipe grid without full page reload when filtering by category" do
      visit recipes_path

      # Verify initial state - all recipes visible
      expect(page).to have_content("3 Recipes Found")
      expect(page).to have_content("Chicken Pasta")
      expect(page).to have_content("Beef Tacos")
      expect(page).to have_content("Caesar Salad")

      # Click on Italian category filter
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Chicken Pasta")
        expect(page).to have_content("Caesar Salad")
      end

      click_link "Italian"

      # Should update only the recipes grid frame without full page reload
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("2 Recipes Found")
        expect(page).to have_content("Chicken Pasta")
        expect(page).to have_content("Caesar Salad")
        expect(page).not_to have_content("Beef Tacos")
      end

      # Header should remain unchanged (no full page reload)
      expect(page).to have_content("All Recipes")
    end

    it "preserves filter state when navigating between pages" do
      # Create enough recipes to trigger pagination
      15.times { |i| create(:recipe, title: "Italian Recipe #{i}", category: "Italian") }

      visit recipes_path

      # Filter by Italian category
      click_link "Italian"

      # Should show filtered results with pagination
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("17 Recipes Found") # 15 + 2 existing Italian recipes
      end

      # Navigate to page 2 within the frame
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2" if page.has_link?("2")
      end

      # Should maintain category filter on page 2
      expect(current_url).to include("category=Italian")
      expect(current_url).to include("page=2")
    end

    it "updates pagination controls within turbo frame" do
      # Create enough recipes to trigger pagination
      15.times { |i| create(:recipe, title: "Recipe #{i}") }

      visit recipes_path

      # Should have pagination controls in recipes-grid frame
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_link("2")
      end

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Should update recipes-grid frame with new content and pagination
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Recipe")
        expect(page).to have_link("1") # Previous page link
      end
    end
  end

  describe "search form with Turbo Frames" do
    it "updates recipe grid when searching by ingredients" do
      # Create recipes with specific ingredients
      chicken_recipe = create(:recipe, title: "Chicken Curry")
      chicken_ingredient = create(:ingredient, name: "chicken")
      create(:recipe_ingredient, recipe: chicken_recipe, ingredient: chicken_ingredient, raw_text: "1 lb chicken")

      beef_recipe = create(:recipe, title: "Beef Stew")
      beef_ingredient = create(:ingredient, name: "beef")
      create(:recipe_ingredient, recipe: beef_recipe, ingredient: beef_ingredient, raw_text: "2 lbs beef")

      visit recipes_path

      # Search for chicken in the ingredients search form
      within 'turbo-frame[id="filters"]' do
        fill_in "ingredients", with: "chicken"
        click_button "Search Recipes"
      end

      # Should stay on recipes page but with search parameters
      expect(current_path).to eq(recipes_path)
      expect(current_url).to include("ingredients=chicken")

      # Should update the recipes grid with filtered results
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Chicken Curry")
        expect(page).not_to have_content("Beef Stew")
      end
    end
  end

  describe "recipe grid structure" do
    it "contains properly structured turbo frames" do
      visit recipes_path

      # Verify main turbo frames exist
      expect(page).to have_css('turbo-frame[id="filters"]')
      expect(page).to have_css('turbo-frame[id="recipes-grid"]')

      # Pagination should be inside recipes-grid frame
      within 'turbo-frame[id="recipes-grid"]' do
        # Should have recipe cards
        expect(page).to have_css('.recipe-card', count: 3)
      end
    end
  end
end
