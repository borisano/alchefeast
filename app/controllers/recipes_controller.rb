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
    @query = params[:q]
    @ingredients = params[:ingredients]&.split(",")&.map(&:strip) || []

    @recipes = Recipe.includes(:ingredients)

    # Filter by text query if provided
    if @query.present?
      @recipes = @recipes.where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%")
    end

    # Filter by ingredients if provided
    if @ingredients.present?
      # Find recipes that contain any of the specified ingredients
      ingredient_names = @ingredients.map(&:downcase)
      @recipes = @recipes.joins(:ingredients)
                        .where("LOWER(ingredients.name) IN (?)", ingredient_names)
                        .distinct
    end

    @recipes = @recipes.limit(20) # Limit results for performance
  end
end
