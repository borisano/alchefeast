class CreateRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity, precision: 8, scale: 3
      t.string :unit
      t.text :raw_text

      t.timestamps
    end

    add_index :recipe_ingredients, [ :recipe_id, :ingredient_id ], unique: true
  end
end
