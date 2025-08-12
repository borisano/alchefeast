class AiInstructionService
  class << self
    def generate_instructions(recipe)
      return dummy_instructions if Rails.env.test? || openai_client.nil?

      prompt = build_prompt(recipe)

      Rails.logger.debug("Making OpenAI API call with prompt: #{prompt[0..100]}...")

      response = openai_client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: "You are a professional chef assistant. Generate clear, step-by-step cooking instructions for the given recipe. Format your response as a simple numbered list starting with '1.' with NO markdown formatting, NO headers, NO bold text, NO titles. Just plain numbered steps. You also pretend to be an Alchemist, for fun. so before the recepie steps, give some clever alchemy-based reflection on the dish that is being made. make this reflection short, 2-3 sentances."
            },
            {
              role: "user",
              content: prompt
            }
          ],
          max_tokens: 500,
          temperature: 0.7
        }
      )

      Rails.logger.debug("OpenAI API response: #{response.inspect}")
      extract_content(response)
    rescue OpenAI::Error => e
      Rails.logger.error("OpenAI API error (OpenAI::Error): #{e.class} - #{e.message}")
      handle_openai_error(e)
    rescue Faraday::Error => e
      Rails.logger.error("Faraday HTTP error: #{e.class} - #{e.message}")
      handle_faraday_error(e)
    rescue => e
      Rails.logger.error("Unexpected error in generate_instructions: #{e.class} - #{e.message}")
      raise "Failed to generate AI instructions: #{e.message}"
    end

    private

    def openai_client
      @openai_client ||= begin
        api_key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.openai_api_key
        Rails.logger.debug("API key present: #{api_key.present?}")
        return nil unless api_key.present?

        client = OpenAI::Client.new(access_token: api_key)
        Rails.logger.debug("OpenAI client created successfully")
        client
      end
    end

    def build_prompt(recipe)
      ingredients_list = recipe.recipe_ingredients.includes(:ingredient).map do |ri|
        "#{ri.quantity} #{ri.unit} #{ri.ingredient.name}"
      end.join("\n")

      <<~PROMPT
        Recipe: #{recipe.title}

        Ingredients:
        #{ingredients_list}

        Additional Info:
        - Prep time: #{recipe.prep_time} minutes
        - Cook time: #{recipe.cook_time} minutes
        - Category: #{recipe.category}
        - Cuisine: #{recipe.cuisine}

        Please provide detailed step-by-step cooking instructions for this recipe.
      PROMPT
    end

    def extract_content(response)
      Rails.logger.debug("Extracting content from response type: #{response.class}")

      # Handle both hash and OpenAI object responses
      content = if response.respond_to?(:dig)
        response.dig("choices", 0, "message", "content")
      elsif response.respond_to?(:[])
        response["choices"]&.first&.dig("message", "content")
      else
        # Try accessing as object properties
        response.choices&.first&.message&.content
      end

      content&.strip || "No instructions generated"
    end

    def handle_openai_error(error)
      case error.message
      when /rate_limit_exceeded|429/
        raise "API rate limit exceeded. Please try again in a few minutes."
      when /invalid_api_key|401/
        raise "Invalid API key or authentication failed."
      when /model_not_found|404/
        raise "Model not available. Please check OpenAI model configuration."
      when /quota_exceeded/
        raise "API quota exceeded. Please check your OpenAI billing."
      else
        raise "OpenAI API error: #{error.message}"
      end
    end

    def handle_faraday_error(error)
      case error
      when Faraday::TooManyRequestsError
        raise "API rate limit exceeded. Please try again in a few minutes."
      when Faraday::UnauthorizedError
        raise "Invalid API key or authentication failed."
      when Faraday::BadRequestError
        raise "Bad request to OpenAI API. Please check the request parameters."
      else
        raise "HTTP error: #{error.message}"
      end
    end

    def dummy_instructions
      "AI steps: #{SecureRandom.hex(8)}"
    end
  end
end
