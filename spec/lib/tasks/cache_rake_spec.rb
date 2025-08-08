require 'rails_helper'
require 'rake'

RSpec.describe 'Cache Rake Tasks', type: :rake do
  before do
    # Load rake tasks
    Rake.application.rake_require 'tasks/cache'
    Rake::Task.define_task(:environment)

    # Use memory store for cache tests instead of null store
    @original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # Clear cache before tests
    Rails.cache.clear
  end

  after do
    # Restore original cache store
    Rails.cache = @original_cache_store
  end

  describe 'cache:refresh_popular_categories' do
    let(:task) { Rake::Task['cache:refresh_popular_categories'] }

    before do
      task.reenable # Allow task to be run multiple times in tests
    end

    context 'with recipes in database' do
      let!(:everyday_recipes) { create_list(:recipe, 5, category: 'Everyday Cooking') }
      let!(:bread_recipes) { create_list(:recipe, 3, category: 'Yeast Bread') }
      let!(:mexican_recipes) { create_list(:recipe, 4, category: 'Mexican Recipes') }

      it 'refreshes the popular categories cache' do
        # Pre-populate cache with old data
        Rails.cache.write('popular_categories', [ 'Old', 'Data' ])
        expect(Rails.cache.read('popular_categories')).to eq([ 'Old', 'Data' ])

        # Run the task
        expect { task.invoke }.to output(/Popular categories cache refreshed with:/).to_stdout

        # Verify cache was refreshed with new data
        cached_categories = Rails.cache.read('popular_categories')
        expect(cached_categories).to include('Everyday Cooking')
        expect(cached_categories).to include('Mexican Recipes')
        expect(cached_categories).to include('Yeast Bread')
        expect(cached_categories).not_to include('Old')
        expect(cached_categories).not_to include('Data')
      end

      it 'outputs the refreshed categories' do
        expect { task.invoke }.to output(/Everyday Cooking.*Mexican Recipes.*Yeast Bread/).to_stdout
      end

      it 'pre-warms the cache after clearing' do
        task.invoke

        # Verify cache is populated
        expect(Rails.cache.read('popular_categories')).to be_present
        expect(Rails.cache.read('popular_categories')).to be_an(Array)
      end
    end

    context 'with no recipes' do
      it 'handles empty database gracefully' do
        expect { task.invoke }.to output(/Popular categories cache refreshed with:/).to_stdout
        expect(Rails.cache.read('popular_categories')).to eq([])
      end
    end
  end

  describe 'cache:clear_all' do
    let(:task) { Rake::Task['cache:clear_all'] }

    before do
      task.reenable
    end

    it 'clears all application caches' do
      # Pre-populate cache with test data
      Rails.cache.write('test_key', 'test_value')
      Rails.cache.write('popular_categories', [ 'Test', 'Categories' ])

      expect(Rails.cache.read('test_key')).to eq('test_value')
      expect(Rails.cache.read('popular_categories')).to eq([ 'Test', 'Categories' ])

      # Run the task
      expect { task.invoke }.to output(/All caches cleared/).to_stdout

      # Verify all caches are cleared
      expect(Rails.cache.read('test_key')).to be_nil
      expect(Rails.cache.read('popular_categories')).to be_nil
    end

    it 'outputs confirmation message' do
      expect { task.invoke }.to output(/All caches cleared/).to_stdout
    end
  end

  describe 'cache integration with Recipe model' do
    let!(:recipes) { create_list(:recipe, 5, category: 'Test Category') }

    it 'integrates with Recipe.refresh_popular_categories_cache' do
      # Populate cache
      Recipe.popular_categories
      expect(Rails.cache.read('popular_categories')).to be_present

      # Use Recipe model method to clear cache
      Recipe.refresh_popular_categories_cache
      expect(Rails.cache.read('popular_categories')).to be_nil

      # Verify rake task uses the same cache key
      Rake::Task['cache:refresh_popular_categories'].reenable
      Rake::Task['cache:refresh_popular_categories'].invoke

      expect(Rails.cache.read('popular_categories')).to include('Test Category')
    end
  end
end
