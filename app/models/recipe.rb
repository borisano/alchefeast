class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true
  validates :ratings, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  validates :cook_time, :prep_time, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_total_time

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_cuisine, ->(cuisine) { where(cuisine: cuisine) if cuisine.present? }
  scope :by_max_time, ->(max_time) { where("total_time <= ?", max_time) if max_time.present? }
  scope :by_min_rating, ->(min_rating) { where("ratings >= ?", min_rating) if min_rating.present? }

  # Find recipes containing specific ingredients
  scope :with_ingredients, ->(ingredient_names) {
    return none if ingredient_names.blank?

    joins(:ingredients)
      .where("LOWER(ingredients.name) IN (?)", ingredient_names.map(&:downcase))
      .group("recipes.id")
      .having("COUNT(DISTINCT ingredients.id) = ?", ingredient_names.length)
  }

  # Find recipes containing any of the specified ingredients (for partial matching)
  scope :with_any_ingredients, ->(ingredient_names) {
    return none if ingredient_names.blank?

    joins(:ingredients)
      .where("LOWER(ingredients.name) IN (?)", ingredient_names.map(&:downcase))
      .distinct
  }

  # Get a random food image from Foodish API
  def image_url
    # Use recipe ID to ensure consistent image for same recipe
    # This creates a pseudo-random but deterministic image selection
    food_categories = [ "biryani", "burger", "butter-chicken", "dessert", "dosa", "idly", "pasta", "pizza", "rice", "samosa" ]
    category_index = id % food_categories.length
    selected_category = food_categories[category_index]

    begin
      # Try to fetch from Foodish API
      require "net/http"
      require "json"

      uri = URI("https://foodish-api.com/api/images/#{selected_category}")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        data = JSON.parse(response.body)
        return data["image"]
      end
    rescue => e
      Rails.logger.warn "Failed to fetch image from Foodish API: #{e.message}"
    end

    # Fallback to a placeholder image if API fails
    "https://via.placeholder.com/400x300/007bff/ffffff?text=#{title.gsub(' ', '+')}"
  end

  # Get top 5 most popular categories (cached for 1 week)
  def self.popular_categories
    Rails.cache.fetch("popular_categories", expires_in: 1.week) do
      Recipe.group(:category)
            .count
            .sort_by(&:last)
            .reverse
            .first(5)
            .map(&:first)
            .compact
            .reject(&:blank?)
    end
  end

  # Clear popular categories cache (useful when data changes significantly)
  def self.refresh_popular_categories_cache
    Rails.cache.delete("popular_categories")
  end

  private

  def calculate_total_time
    if cook_time.present? || prep_time.present?
      self.total_time = (cook_time || 0) + (prep_time || 0)
    end
  end
end
