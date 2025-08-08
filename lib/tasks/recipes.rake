namespace :recipes do
  desc "Import recipes from a JSON file with progress monitoring"
  task :import, [ :file_path, :batch_size ] => :environment do |t, args|
    if args[:file_path].blank?
      puts "Usage: rake recipes:import[path/to/recipes.json,batch_size]"
      puts "Example: rake recipes:import[recipes-en.json,100]"
      puts "Example: rake recipes:import[test_recipes.json]  # batch_size defaults to 100"
      exit 1
    end

    file_path = args[:file_path]
    batch_size = (args[:batch_size] || 100).to_i

    # Handle relative paths from Rails root
    unless file_path.start_with?("/")
      file_path = Rails.root.join(file_path).to_s
    end

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end

    puts "Starting recipe import from: #{file_path}"
    puts "Batch size: #{batch_size}"
    puts "Environment: #{Rails.env}"
    puts "=" * 60

    # Log initial stats
    initial_recipes = Recipe.count
    initial_ingredients = Ingredient.count

    # Create progress callback for detailed logging
    progress_callback = ->(data) do
      # This could be enhanced to write to a file or send to a monitoring service
      # For now, the log_progress method in the service handles output
    end

    importer = RecipeImporterService.new(
      progress_callback: progress_callback,
      batch_size: batch_size
    )

    start_time = Time.current

    begin
      if importer.import_from_file(file_path)
        end_time = Time.current
        duration = (end_time - start_time).round(2)

        puts ""
        puts "=" * 60
        puts "Import completed successfully in #{duration} seconds!"
        puts ""
        puts "Results:"
        puts "  Recipes created: #{importer.results[:created_recipes]}"
        puts "  Recipes updated: #{importer.results[:updated_recipes]}"
        puts "  Ingredients created: #{importer.results[:created_ingredients]}"
        puts ""
        puts "Database changes:"
        puts "  Recipes: #{initial_recipes} → #{Recipe.count} (+#{Recipe.count - initial_recipes})"
        puts "  Ingredients: #{initial_ingredients} → #{Ingredient.count} (+#{Ingredient.count - initial_ingredients})"
        puts "  Total recipe-ingredient associations: #{RecipeIngredient.count}"
        puts ""
        puts "Performance:"
        puts "  Average rate: #{(importer.results[:created_recipes] + importer.results[:updated_recipes]) / duration.to_f} recipes/second"

        # Check for errors
        if importer.errors.any?
          puts ""
          puts "⚠️  #{importer.errors.length} errors occurred:"
          importer.errors.first(10).each do |error|
            puts "  - #{error}"
          end
          puts "  ... and #{importer.errors.length - 10} more" if importer.errors.length > 10
        end
      else
        puts ""
        puts "❌ Import failed with errors:"
        importer.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    rescue Interrupt
      puts ""
      puts "⚠️  Import interrupted by user"
      puts "Processed #{importer.instance_variable_get(:@processed_count)} out of #{importer.instance_variable_get(:@total_count)} recipes"
      puts "You can resume by running the import again (existing recipes will be updated, not duplicated)"
      exit 130
    rescue => e
      puts ""
      puts "❌ Unexpected error during import: #{e.message}"
      puts e.backtrace.first(5).join("\n") if Rails.env.development?
    end
  end

  desc "Import recipes optimized for production (larger batches, logging to file)"
  task :import_production, [ :file_path ] => :environment do |t, args|
    if args[:file_path].blank?
      puts "Usage: rake recipes:import_production[path/to/recipes.json]"
      puts "Example: rake recipes:import_production[recipes-en.json]"
      exit 1
    end

    file_path = args[:file_path]
    log_file = "/tmp/recipe_import_#{Time.current.strftime('%Y%m%d_%H%M%S')}.log"

    # Handle relative paths from Rails root
    unless file_path.start_with?("/")
      file_path = Rails.root.join(file_path).to_s
    end

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end

    puts "Starting production recipe import from: #{file_path}"
    puts "Log file: #{log_file}"
    puts "Environment: #{Rails.env}"
    puts "Process PID: #{Process.pid}"
    puts "=" * 60

    # Redirect output to both console and log file
    original_stdout = $stdout
    log_io = File.open(log_file, "w")

    # Create a custom logger that writes to both
    class DualOutput
      def initialize(console, file)
        @console = console
        @file = file
      end

      def puts(message)
        @console.puts(message)
        @file.puts(message)
        @file.flush  # Ensure immediate write
      end

      def print(message)
        @console.print(message)
        @file.print(message)
        @file.flush
      end
    end

    $stdout = DualOutput.new(original_stdout, log_io)

    begin
      # Use larger batch size for production and disable AR logging for performance
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil if Rails.env.production?

      # Log initial stats
      initial_recipes = Recipe.count
      initial_ingredients = Ingredient.count

      importer = RecipeImporterService.new(batch_size: 500)  # Larger batch for production
      start_time = Time.current

      puts "Initial database state:"
      puts "  Recipes: #{initial_recipes}"
      puts "  Ingredients: #{initial_ingredients}"
      puts ""

      if importer.import_from_file(file_path)
        end_time = Time.current
        duration = (end_time - start_time).round(2)

        puts ""
        puts "=" * 60
        puts "✅ Import completed successfully in #{duration} seconds!"
        puts ""
        puts "Results:"
        puts "  Recipes created: #{importer.results[:created_recipes]}"
        puts "  Recipes updated: #{importer.results[:updated_recipes]}"
        puts "  Ingredients created: #{importer.results[:created_ingredients]}"
        puts ""
        puts "Database changes:"
        puts "  Recipes: #{initial_recipes} → #{Recipe.count} (+#{Recipe.count - initial_recipes})"
        puts "  Ingredients: #{initial_ingredients} → #{Ingredient.count} (+#{Ingredient.count - initial_ingredients})"
        puts "  Total recipe-ingredient associations: #{RecipeIngredient.count}"
        puts ""
        puts "Performance:"
        puts "  Average rate: #{((importer.results[:created_recipes] + importer.results[:updated_recipes]) / duration.to_f).round(2)} recipes/second"
        puts "  Peak memory usage: #{`ps -o rss= -p #{Process.pid}`.strip.to_i / 1024}MB" rescue puts "  Memory info unavailable"

        if importer.errors.any?
          puts ""
          puts "⚠️  #{importer.errors.length} errors occurred:"
          importer.errors.first(10).each do |error|
            puts "  - #{error}"
          end
          puts "  ... and #{importer.errors.length - 10} more" if importer.errors.length > 10
        end

        puts ""
        puts "Log file saved to: #{log_file}"
      else
        puts ""
        puts "❌ Import failed with errors:"
        importer.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    rescue Interrupt
      puts ""
      puts "⚠️  Import interrupted by user"
      exit 130
    rescue => e
      puts ""
      puts "❌ Unexpected error during import: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    ensure
      # Restore original logging and stdout
      ActiveRecord::Base.logger = old_logger
      $stdout = original_stdout
      log_io&.close
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
