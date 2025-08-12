require 'rails_helper'

RSpec.describe RecipesController, type: :controller do
  describe "GET #index" do
    context 'basic functionality' do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "responds with HTML content" do
        get :index
        expect(response.content_type).to include("text/html")
      end

      it "handles category parameter" do
        get :index, params: { category: "Italian" }
        expect(response).to be_successful
      end

      it "handles difficulty parameter" do
        get :index, params: { difficulty: "Easy" }
        expect(response).to be_successful
      end
    end

    context 'pagination' do
      let!(:recipes) { create_list(:recipe, 25) }

      it 'paginates results with 12 recipes per page' do
        get :index
        expect(assigns(:recipes).current_page).to eq(1)
        expect(assigns(:recipes).limit_value).to eq(12)
        expect(assigns(:recipes).count).to eq(12)
      end

      it 'responds to page parameter' do
        get :index, params: { page: 2 }
        expect(assigns(:recipes).current_page).to eq(2)
        expect(assigns(:recipes).count).to eq(12)
      end

      it 'handles last page correctly' do
        get :index, params: { page: 3 }
        expect(assigns(:recipes).current_page).to eq(3)
        expect(assigns(:recipes).count).to eq(1) # 25 total - 24 on first 2 pages = 1 remaining
      end

      it 'includes pagination metadata' do
        get :index
        recipes = assigns(:recipes)
        expect(recipes).to respond_to(:current_page)
        expect(recipes).to respond_to(:total_pages)
        expect(recipes).to respond_to(:total_count)
        expect(recipes).to respond_to(:offset_value)
        expect(recipes).to respond_to(:limit_value)
      end

      context 'with category filter' do
        let!(:italian_recipes) { create_list(:recipe, 15, category: 'Italian') }
        let!(:other_recipes) { create_list(:recipe, 10, category: 'Mexican') }

        it 'paginates filtered results' do
          get :index, params: { category: 'Italian' }
          recipes = assigns(:recipes)
          expect(recipes.total_count).to eq(15)
          expect(recipes.count).to eq(12) # First page of Italian recipes
        end

        it 'maintains category filter across pages' do
          get :index, params: { category: 'Italian', page: 2 }
          recipes = assigns(:recipes)
          expect(recipes.current_page).to eq(2)
          expect(recipes.count).to eq(3) # Remaining Italian recipes
          # Verify all returned recipes are Italian
          expect(recipes.pluck(:category).uniq).to eq([ 'Italian' ])
        end
      end
    end

    context 'popular categories' do
      let!(:everyday_recipes) { create_list(:recipe, 5, category: 'Everyday Cooking') }
      let!(:bread_recipes) { create_list(:recipe, 3, category: 'Yeast Bread') }
      let!(:mexican_recipes) { create_list(:recipe, 4, category: 'Mexican Recipes') }

      it 'assigns popular categories' do
        get :index
        expect(assigns(:popular_categories)).to be_present
        expect(assigns(:popular_categories)).to be_an(Array)
      end

      it 'returns empty array when popular categories is empty' do
        allow(Recipe).to receive(:popular_categories).and_return([])
        get :index
        expect(assigns(:popular_categories)).to eq([])
      end
    end
  end

  describe "GET #show" do
    let!(:test_recipe) { create(:recipe, title: 'Test Recipe') }

    it "returns a success response for valid recipe id" do
      get :show, params: { id: test_recipe.id }
      expect(response).to be_successful
    end

    it "redirects for invalid recipe id" do
      get :show, params: { id: 999 }
      expect(response).to redirect_to(recipes_path)
      expect(flash[:alert]).to eq("Recipe not found")
    end
  end

  describe "GET #index with search functionality" do
    let!(:recipe1) { create(:recipe, title: 'Chocolate Chip Cookies') }
    let!(:recipe2) { create(:recipe, title: 'Vanilla Cake') }
    let!(:recipe3) { create(:recipe, title: 'Bread Pudding') }

    let!(:ingredient1) { create(:ingredient, name: 'chocolate chips') }
    let!(:ingredient2) { create(:ingredient, name: 'vanilla extract') }
    let!(:ingredient3) { create(:ingredient, name: 'flour') }
    let!(:ingredient4) { create(:ingredient, name: 'sugar') }
    let!(:ingredient5) { create(:ingredient, name: 'eggs') }

    before do
      # Set up recipe-ingredient relationships
      create(:recipe_ingredient, recipe: recipe1, ingredient: ingredient1)
      create(:recipe_ingredient, recipe: recipe1, ingredient: ingredient3)
      create(:recipe_ingredient, recipe: recipe1, ingredient: ingredient4)

      create(:recipe_ingredient, recipe: recipe2, ingredient: ingredient2)
      create(:recipe_ingredient, recipe: recipe2, ingredient: ingredient3)
      create(:recipe_ingredient, recipe: recipe2, ingredient: ingredient5)

      create(:recipe_ingredient, recipe: recipe3, ingredient: ingredient3)
      create(:recipe_ingredient, recipe: recipe3, ingredient: ingredient5)
      create(:recipe_ingredient, recipe: recipe3, ingredient: ingredient4)
    end

    context 'basic search functionality' do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "responds with HTML content" do
        get :index
        expect(response.content_type).to include("text/html")
      end

      it "handles query parameter" do
        get :index, params: { q: "pasta" }
        expect(response).to be_successful
      end

      it "handles ingredients parameter" do
        get :index, params: { ingredients: "eggs,cheese" }
        expect(response).to be_successful
      end
    end

    context 'with no search parameters' do
      it 'returns all recipes' do
        get :index
        expect(assigns(:recipes)).to match_array([ recipe1, recipe2, recipe3 ])
        expect(assigns(:query)).to be_nil
        expect(assigns(:ingredients)).to eq([])
        expect(assigns(:search_type)).to eq('all')
      end
    end

    context 'searching by recipe title' do
      it 'finds recipes with matching title' do
        get :index, params: { q: 'Chocolate' }
        expect(assigns(:recipes)).to include(recipe1)
        expect(assigns(:recipes)).not_to include(recipe2, recipe3)
        expect(assigns(:query)).to eq('Chocolate')
      end

      it 'finds recipes case-insensitively' do
        get :index, params: { q: 'chocolate' }
        expect(assigns(:recipes)).to include(recipe1)
      end

      it 'finds recipes with partial title match' do
        get :index, params: { q: 'Cake' }
        expect(assigns(:recipes)).to include(recipe2)
      end

      it 'returns empty when no title matches' do
        get :index, params: { q: 'Pizza' }
        expect(assigns(:recipes)).to be_empty
      end
    end

    context 'searching by ingredients in title field' do
      it 'finds recipes containing the ingredient' do
        get :index, params: { q: 'chocolate chips' }
        expect(assigns(:recipes)).to include(recipe1)
        expect(assigns(:recipes)).not_to include(recipe2, recipe3)
      end

      it 'finds recipes case-insensitively by ingredient' do
        get :index, params: { q: 'FLOUR' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe2, recipe3 ])
      end
    end

    context 'searching by ingredients field with "all" search type' do
      it 'finds recipes containing all specified ingredients' do
        get :index, params: { ingredients: 'flour, sugar', search_type: 'all' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe3 ])
        expect(assigns(:recipes)).not_to include(recipe2)
      end

      it 'finds recipes with single ingredient' do
        get :index, params: { ingredients: 'vanilla extract', search_type: 'all' }
        expect(assigns(:recipes)).to include(recipe2)
        expect(assigns(:recipes)).not_to include(recipe1, recipe3)
      end

      it 'returns empty when no recipe has all ingredients' do
        get :index, params: { ingredients: 'chocolate chips, vanilla extract', search_type: 'all' }
        expect(assigns(:recipes)).to be_empty
      end

      it 'handles case-insensitive ingredient matching' do
        get :index, params: { ingredients: 'FLOUR, SUGAR', search_type: 'all' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe3 ])
      end

      it 'strips whitespace from ingredient names' do
        get :index, params: { ingredients: ' flour , sugar ', search_type: 'all' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe3 ])
      end

      it 'ignores empty ingredient names' do
        get :index, params: { ingredients: 'flour, , sugar', search_type: 'all' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe3 ])
      end
    end

    context 'searching by ingredients field with "any" search type' do
      it 'finds recipes containing any of the specified ingredients' do
        get :index, params: { ingredients: 'chocolate chips, vanilla extract', search_type: 'any' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe2 ])
        expect(assigns(:recipes)).not_to include(recipe3)
      end

      it 'finds all recipes when searching for common ingredient' do
        get :index, params: { ingredients: 'flour', search_type: 'any' }
        expect(assigns(:recipes)).to match_array([ recipe1, recipe2, recipe3 ])
      end

      it 'returns empty when no recipe has any of the ingredients' do
        get :index, params: { ingredients: 'non-existent-ingredient', search_type: 'any' }
        expect(assigns(:recipes)).to be_empty
      end
    end

    context 'combining title and ingredient search' do
      it 'finds recipes matching both title and ingredient criteria' do
        get :index, params: { q: 'Cake', ingredients: 'vanilla extract', search_type: 'all' }
        expect(assigns(:recipes)).to include(recipe2)
        expect(assigns(:recipes)).not_to include(recipe1, recipe3)
      end

      it 'returns empty when title matches but ingredients do not' do
        get :index, params: { q: 'Cake', ingredients: 'chocolate chips', search_type: 'all' }
        expect(assigns(:recipes)).to be_empty
      end
    end

    context 'search type parameter handling' do
      it 'defaults to "all" when search_type is not provided' do
        get :index, params: { ingredients: 'flour' }
        expect(assigns(:search_type)).to eq('all')
      end

      it 'accepts "any" search type' do
        get :index, params: { ingredients: 'flour', search_type: 'any' }
        expect(assigns(:search_type)).to eq('any')
      end

      it 'accepts "all" search type explicitly' do
        get :index, params: { ingredients: 'flour', search_type: 'all' }
        expect(assigns(:search_type)).to eq('all')
      end
    end

    context 'response and view assignment' do
      it 'assigns all_ingredients for autocomplete' do
        get :index
        expect(assigns(:all_ingredients)).to match_array(Ingredient.distinct.pluck(:name).sort)
      end

      it 'processes ingredients parameter correctly' do
        get :index, params: { ingredients: 'flour, sugar, eggs' }
        expect(assigns(:ingredients)).to eq([ 'flour', 'sugar', 'eggs' ])
      end

      it 'handles empty ingredients parameter' do
        get :index, params: { ingredients: '' }
        expect(assigns(:ingredients)).to eq([])
      end

      it 'handles nil ingredients parameter' do
        get :index
        expect(assigns(:ingredients)).to eq([])
      end
    end

    context 'result limiting' do
      let!(:many_recipes) { create_list(:recipe, 25, title: 'Test Recipe') }

      it 'paginates results with 12 recipes per page' do
        get :index, params: { q: 'Test' }
        recipes = assigns(:recipes)
        expect(recipes.current_page).to eq(1)
        expect(recipes.limit_value).to eq(12)
        expect(recipes.count).to eq(12)
        expect(recipes.total_count).to eq(25)
      end

      it 'responds to page parameter' do
        get :index, params: { q: 'Test', page: 2 }
        recipes = assigns(:recipes)
        expect(recipes.current_page).to eq(2)
        expect(recipes.count).to eq(12)
      end

      it 'handles last page correctly' do
        get :index, params: { q: 'Test', page: 3 }
        recipes = assigns(:recipes)
        expect(recipes.current_page).to eq(3)
        expect(recipes.count).to eq(1) # 25 total - 24 on first 2 pages = 1 remaining
      end

      it 'maintains search parameters across pages' do
        get :index, params: { q: 'Test', ingredients: 'flour', search_type: 'any', page: 2 }
        expect(assigns(:query)).to eq('Test')
        expect(assigns(:ingredients)).to include('flour')
        expect(assigns(:search_type)).to eq('any')
        expect(assigns(:recipes).current_page).to eq(2)
      end
    end
  end
end
