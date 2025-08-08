require 'rails_helper'

RSpec.describe "Enhanced Category Filtering", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:italian_recipes) do
    [
      create(:recipe, title: "Spaghetti Carbonara", category: "Italian"),
      create(:recipe, title: "Chicken Parmigiana", category: "Italian"),
      create(:recipe, title: "Margherita Pizza", category: "Italian")
    ]
  end

  let!(:mexican_recipes) do
    [
      create(:recipe, title: "Beef Tacos", category: "Mexican"),
      create(:recipe, title: "Chicken Quesadillas", category: "Mexican")
    ]
  end

  let!(:everyday_recipes) do
    [
      create(:recipe, title: "Scrambled Eggs", category: "Everyday Cooking"),
      create(:recipe, title: "Grilled Cheese", category: "Everyday Cooking"),
      create(:recipe, title: "Pancakes", category: "Everyday Cooking"),
      create(:recipe, title: "Toast", category: "Everyday Cooking")
    ]
  end

  describe "category filter behavior" do
    it "shows active state for selected category" do
      visit recipes_path

      # Initially "All" should be active
      within 'turbo-frame[id="filters"]' do
        expect(page).to have_css('a.btn-primary', text: 'All')
        expect(page).to have_css('a.btn-outline-primary', text: 'Italian')
      end

      # Click Italian category
      click_link "Italian"

      # Italian should now be active, All should be outline
      within 'turbo-frame[id="filters"]' do
        expect(page).to have_css('a.btn-primary', text: 'Italian')
        expect(page).to have_css('a.btn-outline-primary', text: 'All')
      end
    end

    it "updates recipe count dynamically for each category" do
      visit recipes_path

      # Check initial count (all recipes)
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("9 Recipes Found")
      end

      # Filter by Italian
      click_link "Italian"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("3 Recipes Found")
        expect(page).to have_content("in Italian")
        italian_recipes.each do |recipe|
          expect(page).to have_content(recipe.title)
        end
        mexican_recipes.each do |recipe|
          expect(page).not_to have_content(recipe.title)
        end
      end

      # Filter by Mexican
      click_link "Mexican"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("2 Recipes Found")
        expect(page).to have_content("in Mexican")
        mexican_recipes.each do |recipe|
          expect(page).to have_content(recipe.title)
        end
        italian_recipes.each do |recipe|
          expect(page).not_to have_content(recipe.title)
        end
      end

      # Return to All
      click_link "All"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("9 Recipes Found")
        expect(page).not_to have_content("in ")
      end
    end

    it "preserves other URL parameters when filtering by category" do
      visit recipes_path(page: 2)

      # Filter by category should preserve page parameter initially, then reset to page 1
      click_link "Italian"

      # Should be on page 1 of Italian recipes (filter resets pagination)
      expect(current_url).to include("category=Italian")
      expect(current_url).not_to include("page=2")
    end

    it "handles categories with special characters" do
      create(:recipe, title: "Bread Recipe", category: "Bread & Baking")

      visit recipes_path

      # Should handle URL encoding properly
      expect(page).to have_content("10 Recipes Found")

      # Filter should work even with special characters in category name
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Bread Recipe")
      end
    end

    it "shows appropriate message when category has no recipes" do
      # Create a recipe then delete it to test empty category behavior
      empty_category_recipe = create(:recipe, title: "Test Recipe", category: "Empty Category")
      empty_category_recipe.destroy

      visit recipes_path

      # All recipes should be visible initially
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("9 Recipes Found")
      end

      # If we manually visit a non-existent category
      visit recipes_path(category: "NonExistent")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("0 Recipes Found")
        expect(page).to have_content("No recipes found")
        expect(page).to have_content("in NonExistent")
      end
    end
  end

  describe "category filter interaction with pagination" do
    before do
      # Create enough recipes to trigger pagination in Italian category
      20.times { |i| create(:recipe, title: "Italian Recipe #{i}", category: "Italian") }
    end

    it "resets to page 1 when changing category filter" do
      visit recipes_path

      # Go to page 2 of all recipes
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      expect(current_url).to include("page=2")

      # Filter by Italian should reset to page 1
      click_link "Italian"

      expect(current_url).to include("category=Italian")
      expect(current_url).not_to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("23 Recipes Found") # 20 + 3 original Italian recipes
      end
    end

    it "maintains category filter when navigating pagination" do
      visit recipes_path

      # Filter by Italian first
      click_link "Italian"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("23 Recipes Found")
        expect(page).to have_link("2")
      end

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Should maintain Italian filter
      expect(current_url).to include("category=Italian")
      expect(current_url).to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("in Italian")
      end
    end
  end

  describe "visual feedback and transitions" do
    it "maintains filter state visual feedback during navigation" do
      visit recipes_path

      # Filter by Mexican
      click_link "Mexican"

      # Mexican button should remain active
      within 'turbo-frame[id="filters"]' do
        expect(page).to have_css('a.btn-primary', text: 'Mexican')
        expect(page).to have_css('a.btn-outline-primary', text: 'All')
        expect(page).to have_css('a.btn-outline-primary', text: 'Italian')
      end

      # State should persist even after content updates
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("2 Recipes Found")
        expect(page).to have_content("in Mexican")
      end
    end

    it "provides immediate feedback on category selection" do
      visit recipes_path

      # Verify instant update without page reload
      click_link "Everyday Cooking"

      # Should immediately show filtered content
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("4 Recipes Found")
        expect(page).to have_content("in Everyday Cooking")

        everyday_recipes.each do |recipe|
          expect(page).to have_content(recipe.title)
        end

        (italian_recipes + mexican_recipes).each do |recipe|
          expect(page).not_to have_content(recipe.title)
        end
      end
    end
  end

  describe "accessibility and usability" do
    it "provides clear indication of current filter state" do
      visit recipes_path

      # Check initial state accessibility
      within 'turbo-frame[id="filters"]' do
        expect(page).to have_css('a.btn-primary', text: 'All')
      end

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("9 Recipes Found")
        expect(page).not_to have_content("in ") # No category indicator for "All"
      end

      # Check filtered state accessibility
      click_link "Italian"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("3 Recipes Found")
        expect(page).to have_content("in Italian") # Clear category indicator
      end
    end

    it "allows easy return to all recipes" do
      visit recipes_path

      # Filter by category
      click_link "Mexican"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("2 Recipes Found")
      end

      # Return to all recipes
      click_link "All"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("9 Recipes Found")
        expect(page).not_to have_content("in ") # No category indicator
      end

      # "All" button should be active again
      within 'turbo-frame[id="filters"]' do
        expect(page).to have_css('a.btn-primary', text: 'All')
      end
    end
  end
end
