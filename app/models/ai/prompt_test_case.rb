# A reported problem with the checks the generatechecks prompt is expected to return for it.
# Admins keep these in the prompt playground to see how a prompt or model change affects them.
# == Schema Information
#
# Table name: ai_prompt_test_cases
#
#  id                    :bigint           not null, primary key
#  expected_check_titles :string           default([]), not null, is an Array
#  input                 :jsonb            not null
#  name                  :string           not null
#  prompt_name           :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
module Ai
  class PromptTestCase < ApplicationRecord
    self.table_name = "ai_prompt_test_cases"

    RUN_TIMEOUT = 120

    Result = Data.define(:checks, :error, :model, :duration, :usage) do
      def initialize(checks: nil, error: nil, usage: nil, model:, duration:)
        super
      end

      # USD, nil when the run failed or the model's price is not known
      def cost
        usage&.cost(Gemini.price(model))
      end

      def returned_titles
        Array(checks).filter_map { _1["title"].to_s.strip.presence if _1.is_a?(Hash) }
      end

      def missing_titles(expected) = expected - returned_titles
      def unexpected_titles(expected) = returned_titles - expected

      def passed?(expected)
        error.nil? && checks.is_a?(Array) && returned_titles.sort == expected.sort
      end
    end

    store_accessor :input, :title, :description, :address

    attribute :prompt_name, default: Ai::IssueChecks::PROMPT_NAME

    validates :name, :title, :description, presence: true

    scope :for_prompt, ->(prompt_name) { where(prompt_name:).order(:created_at) }

    def expected_check_titles=(titles)
      super(Array(titles).flat_map { _1.to_s.split(/\r?\n/) }.map(&:strip).compact_blank.uniq)
    end

    def run(prompt:, model:)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = Ai::IssueChecks.request(
        title:, description:, address:,
        system_prompt: Ai::Prompt.replace_placeholders(prompt),
        model:,
        timeout: RUN_TIMEOUT
      )

      Result.new(checks: response.result, usage: response.usage, model:, duration: elapsed_since(started_at))
    rescue Gemini::Error, Faraday::Error, ArgumentError => e
      Result.new(error: e.message, model:, duration: elapsed_since(started_at))
    end

    private

    def elapsed_since(started_at)
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round(1)
    end
  end
end
