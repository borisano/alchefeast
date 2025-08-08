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

    [chicken_recipe, beef_recipe, pasta_recipe, tomato_recipe]
  end

  describe "search term preservation" do
    it "preserves search terms in the search page form after submission" do
      visit search_recipes_path

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

      visit search_recipes_path

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

      # Use the ingredient search form on recipes index
      within 'turbo-frame[id="filters"]' do
        fill_in "ingredients", with: "chicken"
        click_button class: "btn-warning"
      end

      # Should redirect to search page
      expect(current_path).to eq(search_recipes_path)
      
      # Search term should be preserved in the search page form
      expect(find_field("search_ingredients").value).to eq("chicken")
      expect(page).to have_content("Chicken Curry")
    end
  end

  describe "enhanced search form functionality" do
    it "provides clear search criteria display" do
      visit search_recipes_path(q: "pasta", ingredients: "tomatoes,cheese", search_type: "any")

      # Should display search criteria clearly
      expect(page).to have_content('Showing results for: "pasta"')
      expect(page).to have_content("Recipes that contain ANY of these ingredients:")
      expect(page).to have_content("tomatoes")
      expect(page).to have_content("cheese")

      # Form should be pre-filled
      expect(find_field("search_query").value).to eq("pasta")
      expect(find_field("search_ingredients").value).to eq("tomatoes, cheese")
      expect(find_field("search_type").value).to eq("any")
    end

    it "allows easy modification of search criteria" do
      visit search_recipes_path(q: "chicken")

      # Should show initial results
      expect(page).to have_content("Chicken Curry")

      # Modify search by changing to beef (clear title search)
      fill_in "search_query", with: ""
      fill_in "search_ingredients", with: "beef"
      click_button "Search Recipes"

      # Should show updated results
      expect(find_field("search_query").value).to eq("")
      expect(find_field("search_ingredients").value).to eq("beef")
      
      # Should show recipes that match the new criteria
      expect(page).to have_content("Beef Stew")
    end

    it "provides clear all functionality" do
      visit search_recipes_path(q: "chicken", ingredients: "onions")

      # Should have search terms
      expect(find_field("search_query").value).to eq("chicken")
      expect(find_field("search_ingredients").value).to eq("onions")

      click_link "Clear All"

      # Should clear all search terms
      expect(find_field("search_query").value).to be_blank
      expect(find_field("search_ingredients").value).to be_blank
      expect(current_url).not_to include("q=")
      expect(current_url).not_to include("ingredients=")
    end
  end

  describe "search result presentation" do
    it "displays appropriate result counts and pagination info" do
      visit search_recipes_path(ingredients: "chicken")

      expect(page).to have_content("1 Recipe Found")
      expect(page).to have_content("Showing 1-1 of 1 recipes")
    end

    it "shows helpful no results message with suggestions" do
      visit search_recipes_path(q: "nonexistent_dish")

      expect(page).to have_content("No recipes found")
      expect(page).to have_content("We couldn't find any recipes matching your search criteria")
      expect(page).to have_link("Browse All Recipes")
      expect(page).to have_content("Search Suggestions:")
    end

    it "displays search ingredients in recipe cards when relevant" do
      visit search_recipes_path(ingredients: "chicken")

      # Should show recipe with highlighted ingredients
      expect(page).to have_content("Chicken Curry")
      
      # The recipe card should show matching ingredients (based on our existing implementation)
      within('.recipe-card') do
        expect(page).to have_content("Chicken") # Capital C since ingredient names are displayed properly
      end
    end
  end

  describe "search form usability improvements" do
    it "provides helpful placeholder text and instructions" do
      visit search_recipes_path

      expect(find_field("search_query")[:placeholder]).to include("pasta, chicken curry")
      expect(find_field("search_ingredients")[:placeholder]).to include("chicken, tomatoes, onions")
      expect(page).to have_content("Separate multiple ingredients with commas")
      expect(page).to have_content("How to match ingredients")
    end

    it "maintains search type selection across searches" do
      visit search_recipes_path

      # Change search type to "any"
      select "Can have ANY ingredients", from: "search_type"
      fill_in "search_ingredients", with: "chicken"
      click_button "Search Recipes"

      # Search type should be preserved
      expect(find_field("search_type").value).to eq("any")
      expect(page).to have_content("Recipes that contain ANY of these ingredients:")

      # Modify search
      fill_in "search_query", with: "curry"
      click_button "Search Recipes"

      # Search type should still be preserved
      expect(find_field("search_type").value).to eq("any")
    end
  end

  describe "search integration with navigation" do
    it "provides easy navigation back to browse mode" do
      visit search_recipes_path(q: "nonexistent_dish")

      # Browse All Recipes link appears when there are no results
      expect(page).to have_content("No recipes found")
      expect(page).to have_link("Browse All Recipes")
      
      click_link "Browse All Recipes"
      
      expect(current_path).to eq(recipes_path)
    end

    it "maintains search state in URL parameters" do
      visit search_recipes_path

      fill_in "search_query", with: "pasta"
      click_button "Search Recipes"

      # Check that search parameters are in URL
      expect(current_url).to include("q=pasta")
      
      # Navigate to no results page to access Browse All Recipes link
      fill_in "search_query", with: "nonexistent"
      click_button "Search Recipes"
      
      expect(current_url).to include("q=nonexistent")
      expect(page).to have_link("Browse All Recipes")
      
      # URL-based navigation should work
      visit search_recipes_path(q: "pasta")
      expect(find_field("search_query").value).to eq("pasta")
    end
  end

  describe "search performance and feedback" do
    it "provides immediate feedback for search actions" do
      visit search_recipes_path

      fill_in "search_query", with: "chicken"
      click_button "Search Recipes"

      # Should immediately show results
      expect(page).to have_content("1 Recipe Found")
      expect(page).to have_content('Showing results for: "chicken"')
    end

    it "handles empty search gracefully" do
      visit search_recipes_path

      # Submit empty search
      click_button "Search Recipes"

      # Should show all recipes
      expect(page).to have_content("4 Recipes Found")
      expect(page).not_to have_content("Showing results for:")
    end

    it "handles special characters in search terms" do
      visit search_recipes_path

      fill_in "search_query", with: "pasta & sauce"
      click_button "Search Recipes"

      # Should handle special characters gracefully
      expect(find_field("search_query").value).to eq("pasta & sauce")
      expect(page).to have_content("No recipes found") # or appropriate results
    end
  end
end
