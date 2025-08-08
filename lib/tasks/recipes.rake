namespace :recipes do
  desc "Import recipes from a JSON file"
  task :import, [ :file_path ] => :environment do |t, args|
    if args[:file_path].blank?
      puts "Usage: rake recipes:import[path/to/recipes.json]"
      puts "Example: rake recipes:import[test_recipes.json]"
      exit 1
    end

    file_path = args[:file_path]

    # Handle relative paths from Rails root
    unless file_path.start_with?("/")
      file_path = Rails.root.join(file_path).to_s
    end

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end

    puts "Starting recipe import from: #{file_path}"
    puts "=" * 50

    importer = RecipeImporterService.new
    start_time = Time.current

    if importer.import_from_file(file_path)
      end_time = Time.current
      duration = (end_time - start_time).round(2)

      puts "Import completed successfully in #{duration} seconds!"
      puts ""
      puts "Results:"
      puts "  Recipes created: #{importer.results[:created_recipes]}"
      puts "  Recipes updated: #{importer.results[:updated_recipes]}"
      puts "  Ingredients created: #{importer.results[:created_ingredients]}"
      puts ""
      puts "Database totals:"
      puts "  Total recipes: #{Recipe.count}"
      puts "  Total ingredients: #{Ingredient.count}"
      puts "  Total recipe-ingredient associations: #{RecipeIngredient.count}"
    else
      puts "Import failed with errors:"
      importer.errors.each do |error|
        puts "  - #{error}"
      end
      exit 1
    end
  end

  desc "Import test recipes (first 5 from recipes-en.json)"
  task import_test: :environment do
    test_file = Rails.root.join("test_recipes.json")

    unless File.exist?(test_file)
      puts "Error: test_recipes.json not found. Creating it first..."

      main_file = Rails.root.join("recipes-en.json")
      unless File.exist?(main_file)
        puts "Error: recipes-en.json not found in Rails root"
        exit 1
      end

      # Create test file with first 5 recipes
      begin
        all_recipes = JSON.parse(File.read(main_file))
        test_recipes = all_recipes.first(5)
        File.write(test_file, JSON.pretty_generate(test_recipes))
        puts "Created test_recipes.json with first 5 recipes"
      rescue JSON::ParserError => e
        puts "Error: Invalid JSON in recipes-en.json: #{e.message}"
        exit 1
      end
    end

    # Import the test recipes
    Rake::Task["recipes:import"].invoke(test_file.to_s)
  end

  desc "Show import statistics"
  task stats: :environment do
    puts "Recipe Database Statistics"
    puts "=" * 30
    puts "Recipes: #{Recipe.count}"
    puts "Ingredients: #{Ingredient.count}"
    puts "Recipe-Ingredient associations: #{RecipeIngredient.count}"
    puts ""

    if Recipe.any?
      puts "Recipe breakdown by category:"
      Recipe.group(:category).count.sort_by { |_, count| -count }.each do |category, count|
        category_name = category.present? ? category : "(no category)"
        puts "  #{category_name}: #{count}"
      end
      puts ""

      puts "Recipe breakdown by cuisine:"
      Recipe.group(:cuisine).count.sort_by { |_, count| -count }.each do |cuisine, count|
        cuisine_name = cuisine.present? ? cuisine : "(no cuisine)"
        puts "  #{cuisine_name}: #{count}"
      end
      puts ""

      puts "Top 10 most common ingredients:"
      Ingredient.joins(:recipe_ingredients)
               .group(:name)
               .count
               .sort_by { |_, count| -count }
               .first(10)
               .each do |ingredient, count|
        puts "  #{ingredient}: #{count} recipes"
      end
    end
  end

  desc "Clear all recipe data"
  task clear: :environment do
    print "Are you sure you want to delete all recipes and ingredients? (y/N): "
    response = STDIN.gets.chomp.downcase

    if response == "y" || response == "yes"
      puts "Clearing all recipe data..."

      RecipeIngredient.delete_all
      Recipe.delete_all
      Ingredient.delete_all

      puts "All recipe data cleared."
    else
      puts "Operation cancelled."
    end
  end
end
