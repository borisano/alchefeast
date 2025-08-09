require 'rails_helper'

RSpec.describe "Enhanced Search Functionality", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:recipes_with_ingredients) do
    # Create recipes with specific ingredients for testing
    chicken_recipe = create(:recipe, title: "Chicken Curry")
    chicken_ingredient = create(:ingredient, name: "chicken")
    create(:recipe_ingredient, recipe: chicken_recipe, ingredient: chicken_ingredient, raw_text: "1 lb chicken")

    beef_recipe = create(:recipe, title: "Beef Stew")
    beef_ingredient = create(:ingredient, name: "beef")
    create(:recipe_ingredient, recipe: beef_recipe, ingredient: beef_ingredient, raw_text: "2 lbs beef")

    pasta_recipe = create(:recipe, title: "Spaghetti Carbonara")
    pasta_ingredient = create(:ingredient, name: "pasta")
    create(:recipe_ingredient, recipe: pasta_recipe, ingredient: pasta_ingredient, raw_text: "8 oz pasta")

    tomato_recipe = create(:recipe, title: "Tomato Soup")
    tomato_ingredient = create(:ingredient, name: "tomatoes")
    create(:recipe_ingredient, recipe: tomato_recipe, ingredient: tomato_ingredient, raw_text: "4 large tomatoes")

    [ chicken_recipe, beef_recipe, pasta_recipe, tomato_recipe ]
  end

  describe "search term preservation" do
    it "preserves search terms in the recipes page form after submission" do
      visit recipes_path

      # Fill in search form - use ingredients that exist in our test recipe
      fill_in "search_query", with: "chicken"
      fill_in "search_ingredients", with: "chicken"
      select "Must have ALL ingredients", from: "search_type"

      click_button "Search Recipes"

      # Search terms should be preserved in the form fields
      expect(find_field("search_query").value).to eq("chicken")
      expect(find_field("search_ingredients").value).to eq("chicken")
      expect(find_field("search_type").value).to eq("all")

      # Should show search results
      expect(page).to have_content("Chicken Curry")
    end

    it "preserves search criteria when navigating pagination" do
      # Create enough recipes to trigger pagination
      15.times { |i|
        recipe = create(:recipe, title: "Chicken Recipe #{i}")
        chicken_ingredient = Ingredient.find_or_create_by(name: "chicken")
        create(:recipe_ingredient, recipe: recipe, ingredient: chicken_ingredient, raw_text: "chicken")
      }

      visit recipes_path

      fill_in "search_ingredients", with: "chicken"
      click_button "Search Recipes"

      # Should show results with pagination
      expect(page).to have_content("16 Recipes Found") # 15 + 1 original chicken recipe
      expect(page).to have_link("2") if page.has_content?("2")

      # Navigate to page 2 if it exists
      if page.has_link?("2")
        click_link "2"

        # Search criteria should be preserved
        expect(find_field("search_ingredients").value).to eq("chicken")
        expect(current_url).to include("ingredients=chicken")
        expect(current_url).to include("page=2")
      end
    end

    it "preserves ingredient search term when initiated from recipes index page" do
      visit recipes_path

      # Use the search form to search by ingredients
      within('#filters') do
        fill_in "search_ingredients", with: "chicken"
        click_button "Search Recipes"
      end

      # Verify search was performed
      expect(page).to have_content("Chicken Curry")
    end
  end

  describe "enhanced search form functionality" do
    it "provides clear search criteria display" do
      visit recipes_path(q: "pasta", ingredients: "tomatoes,cheese", search_type: "any")

      expect(page).to have_content('Showing results for: "pasta"')
      expect(page).to have_content("Recipes that contain ANY of these ingredients:")
      expect(page).to have_content("tomatoes")
      expect(page).to have_content("cheese")
    end

    it "allows easy modification of search criteria" do
      visit recipes_path(q: "chicken")

      expect(page).to have_field("search_query", with: "chicken")

      # Modify search
      fill_in "search_query", with: "beef"
      click_button "Search Recipes"

      expect(page).to have_content("Beef Stew")
      expect(page).not_to have_content("Chicken Curry")
    end

    it "provides clear all functionality" do
      visit recipes_path(q: "chicken", ingredients: "onions")

      expect(page).to have_field("search_query", with: "chicken")

      click_link "Clear All"

      expect(page).to have_field("search_query", with: "")
      expect(page).to have_field("search_ingredients", with: "")
      expect(page).to have_content("Filter Recipes")
    end
  end

  describe "search result presentation" do
    it "displays appropriate result counts and pagination info" do
      visit recipes_path(ingredients: "chicken")

      expect(page).to have_content("1 Recipe Found")
      expect(page).to have_content("Showing 1-1 of 1 recipes")
    end

    it "shows helpful no results message with suggestions" do
      visit recipes_path(q: "nonexistent_dish")

      expect(page).to have_content("No recipes found")
      expect(page).to have_content("Try adjusting your search terms")
    end

    it "displays search ingredients in recipe cards when relevant" do
      visit recipes_path(ingredients: "chicken")

      within('.card', text: 'Chicken Curry') do
        expect(page).to have_content("Matching Ingredients:")
        expect(page).to have_content("Chicken")
      end
    end
  end

  describe "search form usability improvements" do
    it "provides helpful placeholder text and instructions" do
      visit recipes_path

      expect(page).to have_field("search_query", placeholder: "Search for recipe names...")
      expect(page).to have_field("search_ingredients", placeholder: "e.g., chicken, tomatoes, garlic")
      expect(page).to have_content("Separate multiple ingredients with commas")
    end

    it "maintains search type selection across searches" do
      visit recipes_path

      select "Can have ANY ingredients", from: "search_type"
      fill_in "search_ingredients", with: "chicken"
      click_button "Search Recipes"

      expect(page).to have_select("search_type", selected: "Can have ANY ingredients")
    end
  end

  describe "search integration with navigation" do
    it "provides easy navigation back to browse mode" do
      visit recipes_path(q: "nonexistent_dish")

      expect(page).to have_link("Browse All Recipes")

      click_link "Browse All Recipes"

      expect(current_path).to eq(recipes_path)
      expect(current_url).not_to include("q=")
    end

    it "maintains search state in URL parameters" do
      visit recipes_path

      fill_in "search_query", with: "pasta"
      fill_in "search_ingredients", with: "tomatoes"
      select "Can have ANY ingredients", from: "search_type"
      click_button "Search Recipes"

      expect(current_url).to include("q=pasta")
      expect(current_url).to include("ingredients=tomatoes")
      expect(current_url).to include("search_type=any")

      # Verify URL is sharable - visit the same URL again
      visit recipes_path(q: "pasta", ingredients: "tomatoes", search_type: "any")

      expect(page).to have_field("search_query", with: "pasta")
      expect(page).to have_field("search_ingredients", with: "tomatoes")
      expect(page).to have_select("search_type", selected: "Can have ANY ingredients")
    end
  end

  describe "search performance and feedback" do
    it "provides immediate feedback for search actions" do
      visit recipes_path

      fill_in "search_ingredients", with: "chicken"
      click_button "Search Recipes"

      expect(page).to have_content("1 Recipe Found")
      expect(page).to have_content("Chicken Curry")
    end

    it "handles empty search gracefully" do
      visit recipes_path

      click_button "Search Recipes"

      # Should show all recipes when no search criteria provided
      expect(page).to have_content("4 Recipes Found") # Our test recipes
    end

    it "handles special characters in search terms" do
      visit recipes_path

      fill_in "search_query", with: "pasta & tomatoes"
      click_button "Search Recipes"

      # Should not crash and handle gracefully
      expect(page).to have_content("recipes")
    end
  end
end
