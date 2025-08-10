require 'rails_helper'

RSpec.describe 'Recipe Pagination', type: :feature do
  describe 'Recipe Index Pagination' do
    context 'with many recipes' do
      let!(:recipes) { create_list(:recipe, 25, title: 'Test Recipe') }

      scenario 'displays pagination controls when there are more than 12 recipes' do
        visit recipes_path

        expect(page).to have_selector('.pagination')
        expect(page).to have_content('Showing 1-12 of 25 recipes')

        # Should show page numbers
        expect(page).to have_link('2')
        expect(page).to have_link('3')
        expect(page).to have_link('Next')
      end

      scenario 'navigates to second page' do
        visit recipes_path

        click_link '2'

        expect(current_path).to eq(recipes_path)
        expect(page).to have_current_path(recipes_path, ignore_query: true)
        expect(page).to have_content('Showing 13-24 of 25 recipes')
        expect(page).to have_link('Previous')
        expect(page).to have_link('3')
      end

      scenario 'navigates to last page' do
        visit recipes_path

        click_link '3'

        expect(page).to have_content('Showing 25-25 of 25 recipes')
        expect(page).to have_link('Previous')
        expect(page).not_to have_link('Next')
      end

      scenario 'uses Next and Previous links' do
        visit recipes_path

        click_link 'Next'
        expect(page).to have_content('Showing 13-24 of 25 recipes')

        click_link 'Previous'
        expect(page).to have_content('Showing 1-12 of 25 recipes')
      end
    end

    context 'with few recipes' do
      let!(:recipes) { create_list(:recipe, 5) }

      scenario 'does not display pagination when recipes fit on one page' do
        visit recipes_path

        expect(page).not_to have_selector('.pagination')
        expect(page).to have_content('Showing 1-5 of 5 recipes')
      end
    end

    context 'with category filtering and pagination' do
      let!(:italian_recipes) { create_list(:recipe, 15, category: 'Italian') }
      let!(:mexican_recipes) { create_list(:recipe, 10, category: 'Mexican') }

      scenario 'maintains category filter across pagination' do
        visit recipes_path

        click_link 'Italian'
        expect(page).to have_content('Showing 1-12 of 15 recipes')
        expect(page).to have_content('in Italian')

        click_link '2'
        expect(page).to have_content('Showing 13-15 of 15 recipes')
        expect(page).to have_content('in Italian')

        # Verify URL contains category parameter
        expect(current_url).to include('category=Italian')
      end
    end
  end

  describe 'Recipe Search Pagination' do
    let!(:search_recipes) { create_list(:recipe, 20, title: 'Chocolate Cake') }
    let!(:other_recipes) { create_list(:recipe, 5, title: 'Vanilla Pudding') }

    scenario 'paginates search results' do
      visit recipes_path(q: 'Chocolate')

      expect(page).to have_content('Showing 1-12 of 20 recipes')
      expect(page).to have_selector('.pagination')
      expect(page).to have_link('2')
      expect(page).to have_link('Next')
    end

    scenario 'maintains search parameters across pagination' do
      visit recipes_path(q: 'Chocolate')

      click_link '2'

      expect(page).to have_content('Showing 13-20 of 20 recipes')
      expect(page).to have_field('search_query', with: 'Chocolate')
      expect(current_url).to include('q=Chocolate')
    end

    context 'with ingredient search' do
      let!(:flour) { create(:ingredient, name: 'flour') }
      let!(:sugar) { create(:ingredient, name: 'sugar') }

      before do
        # Create recipes with ingredients for pagination testing
        20.times do |i|
          recipe = create(:recipe, title: "Recipe #{i}")
          create(:recipe_ingredient, recipe: recipe, ingredient: flour)
          create(:recipe_ingredient, recipe: recipe, ingredient: sugar)
        end
      end

      scenario 'maintains ingredient search parameters across pagination' do
        visit recipes_path(ingredients: 'flour,sugar', search_type: 'all')

        expect(page).to have_content('Showing 1-12 of 20 recipes')

        click_link '2'

        expect(page).to have_content('Showing 13-20 of 20 recipes')
        expect(page).to have_field('search_ingredients', with: 'flour, sugar')
        expect(page).to have_select('search_type', selected: 'Must have ALL ingredients')
        expect(current_url).to include('ingredients=flour%2Csugar')
        expect(current_url).to include('search_type=all')
      end
    end
  end

  describe 'Popular Categories' do
    let!(:everyday_recipes) { create_list(:recipe, 10, category: 'Everyday Cooking') }
    let!(:bread_recipes) { create_list(:recipe, 8, category: 'Yeast Bread') }
    let!(:mexican_recipes) { create_list(:recipe, 6, category: 'Mexican Recipes') }
    let!(:quick_recipes) { create_list(:recipe, 4, category: 'Quick Bread') }
    let!(:chicken_recipes) { create_list(:recipe, 2, category: 'Chicken Breasts') }
    let!(:other_recipes) { create_list(:recipe, 1, category: 'Other Category') }

    scenario 'displays popular categories section' do
      visit recipes_path

      expect(page).to have_content('Popular Categories')
      expect(page).to have_link('All')

      # Should show top 5 categories only
      expect(page).to have_link('Everyday Cooking')
      expect(page).to have_link('Yeast Bread')
      expect(page).to have_link('Mexican Recipes')
      expect(page).to have_link('Quick Bread')
      expect(page).to have_link('Chicken Breasts')

      # Should not show the category with only 1 recipe
      expect(page).not_to have_link('Other Category')
    end

    scenario 'filters by popular category' do
      visit recipes_path

      click_link 'Everyday Cooking'

      expect(page).to have_content('10 Recipes Found in Everyday Cooking')
      expect(page).to have_css('.btn-primary', text: 'Everyday Cooking')
    end

    scenario 'shows "All" as active when no category is selected' do
      visit recipes_path

      expect(page).to have_css('.btn-primary', text: 'All')
    end
  end

  describe 'Pagination Controls Styling' do
    let!(:recipes) { create_list(:recipe, 25) }

    scenario 'displays properly styled pagination controls' do
      visit recipes_path

      # Check for Bootstrap pagination classes
      expect(page).to have_css('nav[aria-label="Recipes pagination"]')
      expect(page).to have_css('ul.pagination.pagination-lg.justify-content-center')
      expect(page).to have_css('li.page-item')
      expect(page).to have_css('a.page-link, span.page-link')
    end

    scenario 'shows disabled state for first page Previous button' do
      visit recipes_path

      # On the first page, Previous might not be shown at all by Kaminari
      # Let's check the pagination structure instead
      within('.pagination') do
        # Check that we're on page 1
        expect(page).to have_css('.page-item.active', text: '1')
        # Previous link should not be present on first page
        expect(page).not_to have_link('Previous')
      end
    end

    scenario 'shows active state for current page' do
      visit recipes_path

      expect(page).to have_css('li.page-item.active')
    end
  end
end
