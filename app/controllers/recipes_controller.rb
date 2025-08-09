class RecipesController < ApplicationController
  def index
    # Get real recipes from database
    @recipes = Recipe.includes(:ingredients)

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

    # Fallback to hardcoded categories if cache returns empty
    @popular_categories = [ "Everyday Cooking", "Yeast Bread", "Mexican Recipes", "Quick Bread", "Chicken Breasts" ] if @popular_categories.empty?

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

    # Filter by category if provided
    if params[:category].present?
      @recipes = @recipes.where(category: params[:category])
    end

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

    # Add pagination
    @recipes = @recipes.page(params[:page]).per(12)

    # Get all available ingredients for autocomplete/suggestions
    @all_ingredients = Ingredient.distinct.pluck(:name).sort
  end
end
