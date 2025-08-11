class AddAiInstructionsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :ai_instructions, :text
    add_column :recipes, :ai_instructions_status, :integer, null: false, default: 0
    add_column :recipes, :ai_instructions_generated_at, :datetime
    add_column :recipes, :ai_instructions_error, :text

    add_index :recipes, :ai_instructions_status
  end
end
