class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_name

  scope :search_by_name, ->(query) { where("name LIKE ?", "%#{query.downcase}%") }

  private

  def normalize_name
    self.name = name.downcase.strip if name.present?
  end
end
