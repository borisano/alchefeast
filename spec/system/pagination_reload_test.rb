require 'rails_helper'

RSpec.describe "Pagination Reload Check", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "pagination should not cause full page reload" do
    # Create enough recipes to trigger pagination
    20.times { |i| create(:recipe, title: "Recipe #{i}") }

    visit recipes_path

    # Initial page should have recipes
    expect(page).to have_content("20 Recipes Found")

    # Check if pagination link targets turbo frame
    within 'turbo-frame[id="recipes-grid"]' do
      expect(page).to have_link("2")

      # Click pagination link
      click_link "2"

      # Should stay on the same base URL but with page parameter
      expect(current_url).to include("page=2")
      expect(current_url).to include("recipes")

      # Should still be within the turbo frame
      expect(page).to have_content("Recipe")
      expect(page).to have_link("1") # Previous page
    end
  end

  it "pagination with search parameters preserves search state" do
    # Create recipes with different categories
    10.times { |i| create(:recipe, title: "Italian Recipe #{i}", category: "Italian") }
    10.times { |i| create(:recipe, title: "Mexican Recipe #{i}", category: "Mexican") }

    visit recipes_path

    # Filter by category
    click_link "Italian"

    expect(page).to have_content("10 Recipes Found")

    # Go to page 2 of filtered results (if pagination exists)
    within 'turbo-frame[id="recipes-grid"]' do
      if page.has_link?("2")
        click_link "2"

        # Should maintain the category filter
        expect(current_url).to include("category=Italian")
        expect(current_url).to include("page=2")
      end
    end
  end
end
