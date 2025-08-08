require "set"

class RecipeImporterService
  attr_reader :results, :errors

  def initialize
    @results = {
      created_recipes: 0,
      created_ingredients: 0,
      updated_recipes: 0,
      errors: []
    }
    @errors = []
  end

  def import_from_file(file_path)
    raise ArgumentError, "File does not exist: #{file_path}" unless File.exist?(file_path)

    begin
      json_data = JSON.parse(File.read(file_path))
      import_recipes(json_data)
    rescue JSON::ParserError => e
      @errors << "Invalid JSON format: #{e.message}"
      false
    rescue => e
      @errors << "Unexpected error: #{e.message}"
      false
    end

    @errors.empty?
  end

  def import_recipes(recipes_data)
    recipes_data.each_with_index do |recipe_data, index|
      begin
        import_single_recipe(recipe_data)
      rescue => e
        @errors << "Error importing recipe at index #{index}: #{e.message}"
      end
    end
  end

  private

  def import_single_recipe(recipe_data)
    # Check if recipe already exists
    existing_recipe = Recipe.find_by(title: recipe_data["title"])

    if existing_recipe
      update_existing_recipe(existing_recipe, recipe_data)
    else
      create_new_recipe(recipe_data)
    end
  end

  def create_new_recipe(recipe_data)
    ActiveRecord::Base.transaction do
      # Create the recipe
      recipe = Recipe.create!(
        title: recipe_data["title"],
        cook_time: recipe_data["cook_time"],
        prep_time: recipe_data["prep_time"],
        ratings: recipe_data["ratings"],
        cuisine: normalize_string(recipe_data["cuisine"]),
        category: normalize_string(recipe_data["category"]),
        author: normalize_string(recipe_data["author"]),
        image_url: recipe_data["image"]
      )

      # Process ingredients
      process_ingredients(recipe, recipe_data["ingredients"])

      @results[:created_recipes] += 1
    end
  end

  def update_existing_recipe(recipe, recipe_data)
    ActiveRecord::Base.transaction do
      # Update recipe attributes
      recipe.update!(
        cook_time: recipe_data["cook_time"],
        prep_time: recipe_data["prep_time"],
        ratings: recipe_data["ratings"],
        cuisine: normalize_string(recipe_data["cuisine"]),
        category: normalize_string(recipe_data["category"]),
        author: normalize_string(recipe_data["author"]),
        image_url: recipe_data["image"]
      )

      # Clear existing recipe ingredients and recreate them
      recipe.recipe_ingredients.destroy_all
      process_ingredients(recipe, recipe_data["ingredients"])

      @results[:updated_recipes] += 1
    end
  end

  def process_ingredients(recipe, ingredients_list)
    return unless ingredients_list.is_a?(Array)

    # Track ingredients already added to this recipe to avoid duplicates
    added_ingredients = Set.new

    ingredients_list.each do |ingredient_text|
      next if ingredient_text.blank?

      # Parse the ingredient text to extract name and quantity/unit
      parsed_ingredient = parse_ingredient_text(ingredient_text)

      # Skip if we've already added this ingredient to this recipe
      next if added_ingredients.include?(parsed_ingredient[:name])

      # Find or create the ingredient
      ingredient = find_or_create_ingredient(parsed_ingredient[:name])

      # Create the recipe_ingredient association
      RecipeIngredient.create!(
        recipe: recipe,
        ingredient: ingredient,
        raw_text: ingredient_text,
        quantity: parsed_ingredient[:quantity],
        unit: parsed_ingredient[:unit]
      )

      # Mark this ingredient as added
      added_ingredients.add(parsed_ingredient[:name])
    end
  end

  def find_or_create_ingredient(ingredient_name)
    normalized_name = ingredient_name.downcase.strip

    ingredient = Ingredient.find_by(name: normalized_name)

    unless ingredient
      ingredient = Ingredient.create!(name: normalized_name)
      @results[:created_ingredients] += 1
    end

    ingredient
  end

  def parse_ingredient_text(text)
    # Simple regex to extract quantity, unit, and ingredient name
    # Examples: "1 cup flour", "2 tablespoons olive oil", "3 large eggs"

    # Match patterns like: number + fraction + unit + ingredient
    match = text.match(/^(\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)*?)\s+(.+)$/) ||
            text.match(/^(\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s+(.+)$/) ||
            text.match(/^(.+)$/)

    if match
      if match.length == 4  # quantity + unit + ingredient
        quantity_str = match[1].strip
        unit = match[2].strip
        ingredient_name = match[3].strip
      elsif match.length == 3  # quantity + ingredient (no specific unit)
        quantity_str = match[1].strip
        unit = nil
        ingredient_name = match[2].strip
      else  # just ingredient name
        quantity_str = nil
        unit = nil
        ingredient_name = match[1].strip
      end
    else
      quantity_str = nil
      unit = nil
      ingredient_name = text.strip
    end

    # Convert quantity string to decimal
    quantity = nil
    if quantity_str
      begin
        # Handle fractions and mixed numbers
        if quantity_str.include?("/")
          # Handle mixed numbers like "1 1/2" or simple fractions like "1/2"
          parts = quantity_str.split(/\s+/)
          if parts.length == 2 && parts[1].include?("/")
            # Mixed number: "1 1/2"
            whole = parts[0].to_f
            fraction_parts = parts[1].split("/")
            fraction = fraction_parts[0].to_f / fraction_parts[1].to_f
            quantity = whole + fraction
          elsif parts.length == 1 && parts[0].include?("/")
            # Simple fraction: "1/2"
            fraction_parts = parts[0].split("/")
            quantity = fraction_parts[0].to_f / fraction_parts[1].to_f
          end
        else
          quantity = quantity_str.to_f
        end
      rescue
        quantity = nil
      end
    end

    # Clean up ingredient name - remove common adjectives and parentheticals
    ingredient_name = clean_ingredient_name(ingredient_name)

    {
      quantity: quantity,
      unit: unit,
      name: ingredient_name
    }
  end

  def clean_ingredient_name(name)
    # Remove common descriptors and extract the core ingredient
    # Examples: "large eggs" -> "eggs", "all-purpose flour" -> "flour"

    # Remove parentheticals
    name = name.gsub(/\([^)]*\)/, "").strip

    # Remove common adjectives (but keep compound ingredient names)
    adjectives_to_remove = %w[
      large medium small extra fresh frozen dried ground chopped
      diced minced sliced crushed whole shredded grated finely
      coarsely roughly thinly thickly lean boneless skinless
      unsalted salted sweetened unsweetened packed unpacked
      active dry instant quick-cooking long-grain short-grain
      all-purpose bread whole wheat white brown raw cooked
    ]

    words = name.split(/\s+/)

    # Keep at least the last word (the main ingredient)
    if words.length > 1
      filtered_words = words.reject do |word|
        adjectives_to_remove.include?(word.downcase.gsub(/[^a-z]/, ""))
      end

      # Always keep at least the last word
      filtered_words = [ words.last ] if filtered_words.empty?
      name = filtered_words.join(" ")
    end

    name.strip
  end

  def normalize_string(str)
    return nil if str.blank?
    str.strip.empty? ? nil : str.strip
  end
end
