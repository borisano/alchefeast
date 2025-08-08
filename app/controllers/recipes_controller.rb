class RecipesController < ApplicationController
  def index
    # Get real recipes from database
    @recipes = Recipe.includes(:ingredients)

    # Filter by category if provided
    if params[:category].present?
      @recipes = @recipes.where(category: params[:category])
    end

    # Get available categories from database
    @categories = Recipe.distinct.pluck(:category).compact.reject(&:blank?)

    # Fallback to empty arrays if no data
    @categories = [ "Italian", "Indian", "Salad", "Asian", "Dessert" ] if @categories.empty?
  end

  def show
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)
  rescue ActiveRecord::RecordNotFound
    redirect_to recipes_path, alert: "Recipe not found"
  end

  def search
    # Handle navbar search input (could be recipe name or comma-separated ingredients)
    if params[:search_input].present?
      search_input = params[:search_input].strip
      if search_input.include?(",")
        # Treat as ingredient search
        params[:ingredients] = search_input
      else
        # Treat as recipe name search
        params[:q] = search_input
      end
    end

    @query = params[:q]
    @ingredients = params[:ingredients]&.split(",")&.map(&:strip)&.reject(&:blank?) || []
    @search_type = params[:search_type] || "all" # "all" or "any"

    @recipes = Recipe.includes(:ingredients)

    # Filter by text query if provided
    if @query.present?
      # Search in both recipe titles and ingredients
      @recipes = @recipes.left_joins(:ingredients)
                        .where("title LIKE ? OR LOWER(ingredients.name) LIKE ?",
                               "%#{@query}%", "%#{@query.downcase}%")
                        .distinct
    end

    # Filter by ingredients if provided
    if @ingredients.present?
      ingredient_names = @ingredients.map(&:downcase)

      if @search_type == "all"
        # Find recipes that contain ALL of the specified ingredients
        @recipes = @recipes.with_ingredients(ingredient_names)
      else
        # Find recipes that contain ANY of the specified ingredients
        @recipes = @recipes.with_any_ingredients(ingredient_names)
      end
    end

    @recipes = @recipes.limit(20) # Limit results for performance

    # Get all available ingredients for autocomplete/suggestions
    @all_ingredients = Ingredient.distinct.pluck(:name).sort
  end
end
