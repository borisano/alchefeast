require 'rails_helper'

RSpec.describe "Advanced Pagination with Turbo Frames", type: :system do
  before do
    driven_by(:rack_test)
  end

  # Create enough recipes to test pagination thoroughly
  let!(:recipes) do
    25.times.map { |i| create(:recipe, title: "Recipe #{i.to_s.rjust(2, '0')}") }
  end

  describe "pagination behavior within turbo frames" do
    it "loads new pages without full page reload" do
      visit recipes_path

      # Should be on page 1 with 12 recipes
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("25 Recipes Found")
        expect(page).to have_content("Showing 1-12 of 25 recipes")
        
        # Should show first 12 recipes
        (0..11).each do |i|
          expect(page).to have_content("Recipe #{i.to_s.rjust(2, '0')}")
        end
        
        # Should not show recipes from page 2
        expect(page).not_to have_content("Recipe 12")
      end

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Should now show page 2 content
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Showing 13-24 of 25 recipes")
        
        # Should show recipes 12-23 (0-indexed in creation)
        (12..23).each do |i|
          expect(page).to have_content("Recipe #{i.to_s.rjust(2, '0')}")
        end
        
        # Should not show recipes from page 1
        expect(page).not_to have_content("Recipe 01")
      end

      # Page header should remain unchanged (no full reload)
      expect(page).to have_content("All Recipes")
    end

    it "maintains consistent pagination controls" do
      visit recipes_path

      within 'turbo-frame[id="recipes-grid"]' do
        # On page 1, should have Next but no Previous
        expect(page).to have_link("2")
        expect(page).to have_link("3")
        expect(page).to have_link("Next")
        expect(page).not_to have_link("Previous")
      end

      # Go to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      within 'turbo-frame[id="recipes-grid"]' do
        # On page 2, should have both Previous and Next
        expect(page).to have_link("1")
        expect(page).to have_link("3")
        expect(page).to have_link("Previous")
        expect(page).to have_link("Next")
      end

      # Go to last page (page 3 - 25 recipes / 12 per page = 3 pages)
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "3"
      end

      within 'turbo-frame[id="recipes-grid"]' do
        # On last page, should have Previous but no Next
        expect(page).to have_link("1")
        expect(page).to have_link("2")
        expect(page).to have_link("Previous")
        expect(page).not_to have_link("Next")
        
        # Should show the remaining recipe
        expect(page).to have_content("Showing 25-25 of 25 recipes")
        expect(page).to have_content("Recipe 24")
      end
    end

    it "handles pagination with filtered results" do
      # Create additional Italian recipes to test filtering + pagination
      15.times { |i| create(:recipe, title: "Italian Recipe #{i}", category: "Italian") }

      visit recipes_path

      # Filter by Italian category
      click_link "Italian"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("15 Recipes Found")
        expect(page).to have_content("in Italian")
        expect(page).to have_content("Showing 1-12 of 15 recipes")
      end

      # Navigate to page 2 of Italian recipes
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Should maintain Italian filter on page 2
      expect(current_url).to include("category=Italian")
      expect(current_url).to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("in Italian")
        expect(page).to have_content("Showing 13-15 of 15 recipes")
      end
    end

    it "provides smooth navigation between pages" do
      visit recipes_path

      # Test navigation through multiple pages
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      expect(current_url).to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        click_link "3"
      end

      expect(current_url).to include("page=3")

      # Navigate back using Previous
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "Previous"
      end

      expect(current_url).to include("page=2")

      # Navigate back to first page
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "1"
      end

      expect(current_url).not_to include("page=")
    end
  end

  describe "pagination performance and user experience" do
    it "maintains scroll position appropriately" do
      visit recipes_path

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Content should update without jumping to top of page
      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Showing 13-24 of 25 recipes")
      end

      # Page header should still be visible (no full page reload)
      expect(page).to have_content("All Recipes")
    end

    it "provides clear pagination information" do
      visit recipes_path

      within 'turbo-frame[id="recipes-grid"]' do
        # Should show clear pagination info
        expect(page).to have_content("25 Recipes Found")
        expect(page).to have_content("Showing 1-12 of 25 recipes")
      end

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      within 'turbo-frame[id="recipes-grid"]' do
        # Should update pagination info
        expect(page).to have_content("25 Recipes Found")
        expect(page).to have_content("Showing 13-24 of 25 recipes")
      end
    end

    it "handles edge cases gracefully" do
      # Test with exactly 12 recipes (no pagination needed)
      Recipe.destroy_all
      12.times { |i| create(:recipe, title: "Exact Recipe #{i}") }

      visit recipes_path

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("12 Recipes Found")
        expect(page).to have_content("Showing 1-12 of 12 recipes")
        
        # Should not have pagination controls
        expect(page).not_to have_link("2")
        expect(page).not_to have_link("Next")
      end
    end

    it "handles invalid page numbers gracefully" do
      visit recipes_path(page: 999)

      # Should redirect to last valid page or show appropriate content
      within 'turbo-frame[id="recipes-grid"]' do
        # Should still show content (Rails/Kaminari handles this)
        expect(page).to have_content("Recipes Found")
      end
    end
  end

  describe "pagination accessibility" do
    it "provides accessible pagination controls" do
      visit recipes_path

      within 'turbo-frame[id="recipes-grid"]' do
        # Should have properly structured pagination
        expect(page).to have_css('.pagination')
        
        # Current page should be identifiable (Bootstrap classes)
        expect(page).to have_css('.page-item.active')
        
        # Links should be navigable
        expect(page).to have_link("2")
        expect(page).to have_link("Next")
      end
    end

    it "provides clear indication of current page" do
      visit recipes_path

      within 'turbo-frame[id="recipes-grid"]' do
        # Page 1 should be active (using Bootstrap pagination classes)
        expect(page).to have_css('.pagination .page-item.active', text: '1')
      end

      # Navigate to page 2
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      within 'turbo-frame[id="recipes-grid"]' do
        # Page 2 should now be active
        expect(page).to have_css('.pagination .page-item.active', text: '2')
      end
    end
  end

  describe "pagination with search and filters" do
    before do
      # Create recipes with different categories for testing
      Recipe.destroy_all
      20.times { |i| create(:recipe, title: "Italian Recipe #{i}", category: "Italian") }
      15.times { |i| create(:recipe, title: "Mexican Recipe #{i}", category: "Mexican") }
    end

    it "maintains pagination state when combining filters" do
      visit recipes_path

      # Filter by Italian
      click_link "Italian"

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("20 Recipes Found")
        expect(page).to have_content("in Italian")
        expect(page).to have_link("2") # Should have pagination
      end

      # Navigate to page 2 of Italian recipes
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      # Should maintain both filter and pagination
      expect(current_url).to include("category=Italian")
      expect(current_url).to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("in Italian")
        expect(page).to have_content("Showing 13-20 of 20 recipes")
      end
    end

    it "resets pagination when changing filters" do
      visit recipes_path

      # Go to page 2 of all recipes
      within 'turbo-frame[id="recipes-grid"]' do
        click_link "2"
      end

      expect(current_url).to include("page=2")

      # Change filter - should reset to page 1
      click_link "Italian"

      expect(current_url).to include("category=Italian")
      expect(current_url).not_to include("page=2")

      within 'turbo-frame[id="recipes-grid"]' do
        expect(page).to have_content("Showing 1-12 of 20 recipes")
      end
    end
  end
end
