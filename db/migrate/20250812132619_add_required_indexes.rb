class AddRequiredIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for common recipe filtering queries
    add_index :recipes, [ :category, :total_time ], name: 'index_recipes_on_category_and_total_time'
    add_index :recipes, [ :cuisine, :ratings ], name: 'index_recipes_on_cuisine_and_ratings'

    # Add index for text search queries (used in recipes controller)
    add_index :recipes, [ :title, :category ], name: 'index_recipes_on_title_and_category'

    # Add index for ingredient-based searches
    add_index :ingredients, [ :name, :created_at ], name: 'index_ingredients_on_name_and_created_at'

    # Add index for popular categories cache query (group by category with count)
    add_index :recipes, [ :category, :created_at ], name: 'index_recipes_on_category_and_created_at'

    # Add indexes for time-based sorting and filtering
    add_index :recipes, [ :total_time, :ratings ], name: 'index_recipes_on_total_time_and_ratings'
    add_index :recipes, [ :created_at, :category ], name: 'index_recipes_on_created_at_and_category'

    # Add index for cuisine filtering (if missing)
    add_index :recipes, :cuisine, name: 'index_recipes_on_cuisine' unless index_exists?(:recipes, :cuisine)

    # Add partial index for AI instructions status queries
    add_index :recipes, [ :ai_instructions_status, :ai_instructions_generated_at ],
              name: 'index_recipes_on_ai_status_and_generated_at'
  end
end
