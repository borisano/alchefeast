namespace :cache do
  desc "Refresh popular categories cache"
  task refresh_popular_categories: :environment do
    Recipe.refresh_popular_categories_cache

    # Pre-warm the cache
    popular_categories = Recipe.popular_categories

    puts "Popular categories cache refreshed with: #{popular_categories.join(', ')}"
  end

  desc "Clear all application caches"
  task clear_all: :environment do
    Rails.cache.clear
    puts "All caches cleared"
  end
end
