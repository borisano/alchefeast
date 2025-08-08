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
    joins(:ingredients)
      .where(ingredients: { name: ingredient_names })
      .group("recipes.id")
      .having("COUNT(DISTINCT ingredients.id) = ?", ingredient_names.length)
  }

  # Find recipes containing any of the specified ingredients (for partial matching)
  scope :with_any_ingredients, ->(ingredient_names) {
    joins(:ingredients)
      .where(ingredients: { name: ingredient_names })
      .distinct
  }

  private

  def calculate_total_time
    if cook_time.present? || prep_time.present?
      self.total_time = (cook_time || 0) + (prep_time || 0)
    end
  end
end
