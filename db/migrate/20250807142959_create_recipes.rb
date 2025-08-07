class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.integer :cook_time
      t.integer :prep_time
      t.integer :total_time
      t.decimal :ratings, precision: 3, scale: 2
      t.string :cuisine
      t.string :category
      t.string :author
      t.text :image_url

      t.timestamps
    end

    add_index :recipes, :title
    add_index :recipes, :total_time
    add_index :recipes, :category
    add_index :recipes, :ratings
  end
end
