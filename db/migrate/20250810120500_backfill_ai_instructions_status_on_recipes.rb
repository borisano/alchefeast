class BackfillAiInstructionsStatusOnRecipes < ActiveRecord::Migration[8.0]
  def up
    # Ensure all existing records have status 0 (idle)
    execute <<~SQL
      UPDATE recipes
      SET ai_instructions_status = 0
    SQL
  end

  def down
    # No-op: keep current values
  end
end
