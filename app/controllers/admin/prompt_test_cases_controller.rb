# The prompt playground: runs the saved test cases against an edited generatechecks prompt
# and a chosen Gemini model, without changing the prompt in the CMS.
class Admin::PromptTestCasesController < ApplicationController
  layout "admin"

  before_action :set_test_case, only: [ :edit, :update, :destroy, :run ]
  before_action :set_check_titles, only: [ :new, :create, :edit, :update ]

  def index
    @cms_prompt = Ai::Prompt.raw(prompt_name)
    @check_titles = Ai::IssueChecks.titles_in(@cms_prompt)
    @models = available_models
    @test_cases = Ai::PromptTestCase.for_prompt(prompt_name)
  end

  def new
    @test_case = Ai::PromptTestCase.new
  end

  def create
    @test_case = Ai::PromptTestCase.new(test_case_params)

    if @test_case.save
      render turbo_stream: [
        turbo_stream.append("test_cases", partial: "test_case", locals: { test_case: @test_case }),
        turbo_stream.update("new_test_case", partial: "new_link")
      ]
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @test_case.update(test_case_params)
      render turbo_stream: turbo_stream.replace(@test_case, partial: "test_case", locals: { test_case: @test_case })
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @test_case.destroy!

    render turbo_stream: turbo_stream.remove(@test_case)
  end

  def run
    result = @test_case.run(prompt: params.require(:prompt), model: params.require(:model))

    render turbo_stream: turbo_stream.update(
      helpers.dom_id(@test_case, :result),
      partial: "result",
      locals: { test_case: @test_case, result: }
    )
  end

  private

  def prompt_name
    Ai::IssueChecks::PROMPT_NAME
  end

  def set_test_case
    @test_case = Ai::PromptTestCase.for_prompt(prompt_name).find(params[:id])
  end

  def set_check_titles
    @check_titles = Ai::IssueChecks.titles_in(Ai::Prompt.raw(prompt_name))
  end

  def available_models
    Rails.cache.fetch("gemini/models", expires_in: 1.hour) { Gemini.models }
  rescue Gemini::Error, Faraday::Error => e
    Rails.logger.warn("Gemini model list unavailable: #{e.message}")
    [ Gemini::DEFAULT_MODEL ]
  end

  def test_case_params
    params.require(:ai_prompt_test_case).permit(:name, :title, :description, :address, :extra_check_titles, expected_check_titles: []).then do |permitted|
      extra = permitted.delete(:extra_check_titles)
      permitted.merge(expected_check_titles: Array(permitted[:expected_check_titles]) + [ extra ])
    end
  end
end
