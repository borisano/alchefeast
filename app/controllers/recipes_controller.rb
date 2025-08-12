class RecipesController < ApplicationController
  include ActionView::RecordIdentifier

  def index
    # Get real recipes from database
    @recipes = Recipe.includes(:ingredients)

    # Initialize search variables
    @query = params[:q]
    @ingredients = []
    @search_type = params[:search_type] || "all"

    # Handle navbar search_input parameter (fallback for when JS is disabled)
    if params[:search_input].present? && params[:q].blank? && params[:ingredients].blank?
      search_value = params[:search_input].strip
      if search_value.include?(",")
        # Treat as ingredient search
        params[:ingredients] = search_value
      else
        # Treat as recipe name search
        params[:q] = search_value
        @query = search_value
      end
    end

    # Filter by category if provided
    if params[:category].present?
      @recipes = @recipes.where(category: params[:category])
    end

    # Handle search parameters
    if params[:q].present?
      # Search in both recipe titles and ingredients
      @recipes = @recipes.left_joins(:ingredients)
                        .where("title LIKE ? OR LOWER(ingredients.name) LIKE ?",
                               "%#{params[:q]}%", "%#{params[:q].downcase}%")
                        .distinct
    end

    # Handle ingredient search
    if params[:ingredients].present?
      ingredient_names = params[:ingredients].split(",").map(&:strip).reject(&:blank?).map(&:downcase)
      @ingredients = ingredient_names
      search_type = params[:search_type] || "all"

      if search_type == "all"
        # Find recipes that contain ALL of the specified ingredients
        @recipes = @recipes.with_ingredients(ingredient_names)
      else
        # Find recipes that contain ANY of the specified ingredients
        @recipes = @recipes.with_any_ingredients(ingredient_names)
      end
    end

    # Add pagination
    @recipes = @recipes.page(params[:page]).per(12)

    # Get top 5 most popular categories (cached for 1 week)
    @popular_categories = Recipe.popular_categories

    # Set all ingredients for autocomplete (for views that need it)
    @all_ingredients = Ingredient.distinct.pluck(:name).sort

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)
  rescue ActiveRecord::RecordNotFound
    redirect_to recipes_path, alert: "Recipe not found"
  end

  def modal
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)

    respond_to do |format|
      format.html { render partial: "recipe_modal", layout: false }
      format.turbo_stream { render "modal" }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to recipes_path, alert: "Recipe not found" }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("recipe_modal", "<div>Recipe not found</div>")
      end
    end
  end

  def ask_ai
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)

    # Idempotency: if already pending or ready, do nothing quickly
    if @recipe.ai_instructions_status.in?([ "pending", "ready" ])
      respond_to do |format|
        format.html { redirect_back fallback_location: recipe_path(@recipe), notice: "Already processed." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@recipe, :ai_instructions), partial: "recipes/ai_instructions", locals: { recipe: @recipe })
        end
      end
      return
    end

    # Mark as pending immediately
    @recipe.update!(ai_instructions_status: :pending, ai_instructions_error: nil)

    # Enqueue background job to process
    GenerateAiInstructionsJob.perform_later(@recipe.id)

    respond_to do |format|
      format.html { redirect_back fallback_location: recipe_path(@recipe), notice: "Processing..." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(dom_id(@recipe, :ai_instructions), partial: "recipes/ai_instructions", locals: { recipe: @recipe })
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to recipes_path, alert: "Recipe not found" }
      format.turbo_stream { head :not_found }
    end
  rescue => e
    Rails.logger.error("ask_ai failed for Recipe #{params[:id]}: #{e.class} - #{e.message}")
    @recipe.update_columns(ai_instructions_status: Recipe.ai_instructions_statuses[:failed], ai_instructions_error: e.message) if @recipe&.persisted?
    respond_to do |format|
      format.html { redirect_back fallback_location: recipe_path(@recipe), alert: "Failed to generate AI instructions." }
      format.turbo_stream { head :internal_server_error }
    end
  end
end
