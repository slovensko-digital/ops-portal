class Issues::Drafts::ChecksController < ApplicationController
  include Issues::DraftScoped

  def show

  end

  def generate
    Issues::Draft::GenerateChecksJob.perform_now(@draft)
  end
end
