class QuestionsController < ApplicationController
  before_action :ensure_user_onboarded

  def new
  end
end
