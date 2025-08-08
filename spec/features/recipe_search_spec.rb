require 'rails_helper'

RSpec.describe 'Recipe Search', type: :feature do
  let!(:chocolate_cake) { create(:recipe, title: 'Chocolate Cake') }
  let!(:vanilla_cookies) { create(:recipe, title: 'Vanilla Cookies') }
  let!(:bread_pudding) { create(:recipe, title: 'Bread Pudding') }

  let!(:chocolate_chips) { create(:ingredient, name: 'chocolate chips') }
  let!(:vanilla_extract) { create(:ingredient, name: 'vanilla extract') }
  let!(:flour) { create(:ingredient, name: 'flour') }
  let!(:sugar) { create(:ingredient, name: 'sugar') }
  let!(:eggs) { create(:ingredient, name: 'eggs') }

  before do
    # Set up recipe-ingredient relationships
    create(:recipe_ingredient, recipe: chocolate_cake, ingredient: chocolate_chips)
    create(:recipe_ingredient, recipe: chocolate_cake, ingredient: flour)
    create(:recipe_ingredient, recipe: chocolate_cake, ingredient: sugar)
    create(:recipe_ingredient, recipe: chocolate_cake, ingredient: eggs)

    create(:recipe_ingredient, recipe: vanilla_cookies, ingredient: vanilla_extract)
    create(:recipe_ingredient, recipe: vanilla_cookies, ingredient: flour)
    create(:recipe_ingredient, recipe: vanilla_cookies, ingredient: sugar)

    create(:recipe_ingredient, recipe: bread_pudding, ingredient: flour)
    create(:recipe_ingredient, recipe: bread_pudding, ingredient: eggs)
    create(:recipe_ingredient, recipe: bread_pudding, ingredient: sugar)
  end

  describe 'navbar search' do
    it 'allows searching by recipe title from navbar' do
      visit root_path

      within('nav') do
        fill_in 'q', with: 'Chocolate'
        click_button class: 'btn-outline-light'
      end

      expect(page).to have_content('Chocolate Cake')
      expect(page).not_to have_content('Vanilla Cookies')
      expect(page).not_to have_content('Bread Pudding')
    end

    it 'allows searching by ingredient from navbar' do
      visit root_path

      within('nav') do
        fill_in 'q', with: 'chocolate chips'
        click_button class: 'btn-outline-light'
      end

      expect(page).to have_content('Chocolate Cake')
      expect(page).not_to have_content('Vanilla Cookies')
    end
  end

  describe 'advanced search page' do
    before do
      visit search_recipes_path
    end

    it 'displays the search form' do
      expect(page).to have_field('Recipe Name')
      expect(page).to have_field('Ingredients')
      expect(page).to have_select('Search Type')
      expect(page).to have_button('Search Recipes')
    end

    it 'searches by recipe title' do
      fill_in 'Recipe Name', with: 'Vanilla'
      click_button 'Search Recipes'

      expect(page).to have_content('Vanilla Cookies')
      expect(page).not_to have_content('Chocolate Cake')
      expect(page).not_to have_content('Bread Pudding')
    end

    it 'searches by single ingredient with "all" type' do
      fill_in 'Ingredients', with: 'vanilla extract'
      select 'Must have ALL ingredients', from: 'Search Type'
      click_button 'Search Recipes'

      expect(page).to have_content('Vanilla Cookies')
      expect(page).not_to have_content('Chocolate Cake')
    end

    it 'searches by multiple ingredients with "all" type' do
      fill_in 'Ingredients', with: 'flour, sugar, eggs'
      select 'Must have ALL ingredients', from: 'Search Type'
      click_button 'Search Recipes'

      expect(page).to have_content('Chocolate Cake')
      expect(page).to have_content('Bread Pudding')
      expect(page).not_to have_content('Vanilla Cookies')
    end

    it 'searches by multiple ingredients with "any" type' do
      fill_in 'Ingredients', with: 'chocolate chips, vanilla extract'
      select 'Can have ANY ingredients', from: 'Search Type'
      click_button 'Search Recipes'

      expect(page).to have_content('Chocolate Cake')
      expect(page).to have_content('Vanilla Cookies')
      expect(page).not_to have_content('Bread Pudding')
    end

    it 'combines title and ingredient search' do
      fill_in 'Recipe Name', with: 'Cake'
      fill_in 'Ingredients', with: 'chocolate chips'
      select 'Must have ALL ingredients', from: 'Search Type'
      click_button 'Search Recipes'

      expect(page).to have_content('Chocolate Cake')
      expect(page).not_to have_content('Vanilla Cookies')
      expect(page).not_to have_content('Bread Pudding')
    end

    it 'shows appropriate message when no results found' do
      fill_in 'Recipe Name', with: 'Pizza'
      click_button 'Search Recipes'

      expect(page).to have_content('No recipes found')
      expect(page).to have_content('Try adjusting your search terms')
    end

    it 'displays search criteria in results header' do
      fill_in 'Recipe Name', with: 'Chocolate'
      fill_in 'Ingredients', with: 'flour, sugar'
      select 'Must have ALL ingredients', from: 'Search Type'
      click_button 'Search Recipes'

      expect(page).to have_content('Showing results for: "Chocolate"')
      expect(page).to have_content('Recipes that contain ALL of these ingredients:')
      expect(page).to have_content('flour')
      expect(page).to have_content('sugar')
    end

    it 'handles clearing the search' do
      fill_in 'Recipe Name', with: 'Chocolate'
      fill_in 'Ingredients', with: 'flour'
      click_button 'Search Recipes'

      expect(page).to have_content('Chocolate Cake')

      click_link 'Clear All'

      expect(page).to have_field('Recipe Name', with: '')
      expect(page).to have_field('Ingredients', with: '')
      expect(page).to have_content('Refine Your Search')
    end
  end

  describe 'search results display' do
    before do
      visit search_recipes_path
      fill_in 'Ingredients', with: 'flour'
      click_button 'Search Recipes'
    end

    it 'displays recipe cards with proper information' do
      within('.card', text: 'Chocolate Cake') do
        expect(page).to have_content('Chocolate Cake')
        expect(page).to have_link('View Recipe')
        expect(page).to have_css('img')
      end
    end

    it 'shows matching ingredients when searching by ingredients' do
      visit search_recipes_path(ingredients: 'chocolate chips')

      within('.card', text: 'Chocolate Cake') do
        expect(page).to have_content('Matching Ingredients:')
        expect(page).to have_content('Chocolate chips')
      end
    end
  end
end
