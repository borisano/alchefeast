class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :recipe_id, uniqueness: { scope: :ingredient_id }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :raw_text, presence: true

  # For recipe scaling functionality
  def scaled_quantity(scale_factor)
    return nil unless quantity.present?
    quantity * scale_factor
  end

  def display_text(scale_factor = 1)
    if quantity.present? && unit.present? && scale_factor != 1
      scaled_qty = scaled_quantity(scale_factor)
      "#{scaled_qty} #{unit} #{ingredient.name}"
    else
      raw_text
    end
  end
end
