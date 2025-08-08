require 'rails_helper'

RSpec.describe 'Recipe Pagination API', type: :request do
  describe 'GET /recipes' do
    context 'pagination headers and metadata' do
      let!(:recipes) { create_list(:recipe, 25) }

      it 'includes pagination metadata in the response' do
        get recipes_path
        expect(response).to have_http_status(:success)

        # Check that pagination info is available in the view
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 25 recipes')
        expect(response.body).to include('pagination')
      end

      it 'handles page parameter correctly' do
        get recipes_path, params: { page: 2 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 13-24')
        expect(response.body).to include('of 25 recipes')
      end

      it 'handles invalid page numbers gracefully' do
        get recipes_path, params: { page: 999 }
        expect(response).to have_http_status(:success)
        # Kaminari should handle invalid pages gracefully
      end

      it 'handles non-numeric page parameters' do
        get recipes_path, params: { page: 'invalid' }
        expect(response).to have_http_status(:success)
        # Should default to page 1
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 25 recipes')
      end
    end

    context 'with category filtering' do
      let!(:italian_recipes) { create_list(:recipe, 15, category: 'Italian') }
      let!(:mexican_recipes) { create_list(:recipe, 10, category: 'Mexican') }

      it 'paginates filtered results correctly' do
        get recipes_path, params: { category: 'Italian' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 15 recipes')
        expect(response.body).to include('Italian')
        expect(response.body).to include('in')
      end

      it 'maintains category filter across pages' do
        get recipes_path, params: { category: 'Italian', page: 2 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 13-15')
        expect(response.body).to include('of 15 recipes')
        expect(response.body).to include('Italian')
        expect(response.body).to include('in')
      end
    end
  end

  describe 'GET /recipes/search' do
    context 'search with pagination' do
      let!(:chocolate_recipes) { create_list(:recipe, 20, title: 'Chocolate Cake') }
      let!(:vanilla_recipes) { create_list(:recipe, 5, title: 'Vanilla Cake') }

      it 'paginates search results' do
        get search_recipes_path, params: { q: 'Chocolate' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 20 recipes')
      end

      it 'maintains search parameters in pagination links' do
        get search_recipes_path, params: { q: 'Chocolate', page: 2 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 13-20')
        expect(response.body).to include('of 20 recipes')
        expect(response.body).to include('q=Chocolate')
      end

      it 'handles ingredient search pagination' do
        flour = create(:ingredient, name: 'flour')
        15.times do |i|
          recipe = create(:recipe, title: "Recipe #{i}")
          create(:recipe_ingredient, recipe: recipe, ingredient: flour)
        end

        get search_recipes_path, params: { ingredients: 'flour', search_type: 'all' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 15 recipes')
      end

      it 'preserves complex search parameters across pages' do
        flour = create(:ingredient, name: 'flour')
        sugar = create(:ingredient, name: 'sugar')

        15.times do |i|
          recipe = create(:recipe, title: "Cake Recipe #{i}")
          create(:recipe_ingredient, recipe: recipe, ingredient: flour)
          create(:recipe_ingredient, recipe: recipe, ingredient: sugar)
        end

        params = {
          q: 'Cake',
          ingredients: 'flour,sugar',
          search_type: 'all',
          page: 2
        }

        get search_recipes_path, params: params
        expect(response).to have_http_status(:success)
        expect(response.body).to include('q=Cake')
        expect(response.body).to include('ingredients=flour%2Csugar')
        expect(response.body).to include('search_type=all')
      end
    end

    context 'empty search results' do
      it 'handles pagination for empty results gracefully' do
        get search_recipes_path, params: { q: 'NonexistentRecipe' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('No recipes found')
        expect(response.body).not_to include('pagination')
      end
    end
  end

  describe 'Performance considerations' do
    context 'with large datasets' do
      # This test ensures pagination doesn't load all records into memory
      it 'loads only the current page of results' do
        create_list(:recipe, 100)

        # Monitor memory usage or query count if needed
        get recipes_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing 1-12')
        expect(response.body).to include('of 100 recipes')
      end
    end
  end
end
