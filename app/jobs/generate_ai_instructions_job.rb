class GenerateAiInstructionsJob < ApplicationJob
  queue_as :default

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)
    
    # Skip if already processed or not pending
    return unless recipe.ai_instructions_status == "pending"

    # Simulate AI processing
    sleep 2
    random_text = "AI steps: #{SecureRandom.hex(8)}"

    recipe.update!(
      ai_instructions: random_text, 
      ai_instructions_status: :ready, 
      ai_instructions_generated_at: Time.current
    )

    # Broadcast the update to any listening clients
    recipe.broadcast_replace_to(
      "recipe_#{recipe.id}",
      target: ActionView::RecordIdentifier.dom_id(recipe, :ai_instructions),
      partial: "recipes/ai_instructions",
      locals: { recipe: recipe }
    )
  rescue => e
    Rails.logger.error("GenerateAiInstructionsJob failed for Recipe #{recipe_id}: #{e.class} - #{e.message}")
    recipe&.update_columns(
      ai_instructions_status: Recipe.ai_instructions_statuses[:failed], 
      ai_instructions_error: e.message
    )
  end
end
