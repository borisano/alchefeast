require 'rails_helper'

RSpec.describe "recipes/_ai_instructions.html.erb", type: :view do
  let(:recipe) { create(:recipe) }

  context "when recipe has no AI instructions (idle)" do
    before { recipe.update!(ai_instructions_status: :idle) }

    it "shows placeholder text" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("Click \"Ask Alchemist how to cook it\" to generate cooking steps")
      expect(rendered).to include("bi-magic")
    end
  end

  context "when recipe is pending AI generation" do
    before { recipe.update!(ai_instructions_status: :pending) }

    it "shows spinner and generating message" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("Generating AI instructions...")
      expect(rendered).to include("spinner-border")
      expect(rendered).to include("alert-info")
    end
  end

  context "when recipe has AI instructions ready" do
    before do
      recipe.update!(
        ai_instructions_status: :ready,
        ai_instructions: "1. Heat the pan\n2. Add ingredients\n3. Cook for 5 minutes",
        ai_instructions_generated_at: Time.current
      )
    end

    it "shows AI cooking steps" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("Alchemist advice on cooking")
      expect(rendered).to include("1. Heat the pan")
      expect(rendered).to include("2. Add ingredients")
      expect(rendered).to include("3. Cook for 5 minutes")
      expect(rendered).to include("alert-success")
    end

    it "shows generation timestamp" do
    travel_to Time.current do
        render partial: "recipes/ai_instructions", locals: { recipe: recipe }
        expect(rendered).to include("Generated at")
    end
    end
  end

  context "when recipe AI generation failed" do
    before do
      recipe.update!(
        ai_instructions_status: :failed,
        ai_instructions_error: "OpenAI API error"
      )
    end

    it "shows error message" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("Failed to generate AI instructions")
      expect(rendered).to include("alert-danger")
    end

    it "shows error details in expandable section" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("Error details")
      expect(rendered).to include("OpenAI API error")
      expect(rendered).to include("<details")
    end
  end

  context "dom_id generation" do
    it "generates correct dom_id for targeting" do
      render partial: "recipes/ai_instructions", locals: { recipe: recipe }

      expect(rendered).to include("id=\"ai_instructions_recipe_#{recipe.id}\"")
    end
  end
end
