class ErrorsController < ApplicationController
  skip_forgery_protection

  def render_500
    render layout: false, status: 500
  end
  def render_404
    respond_to do |format|
      format.html { render status: 404 }
      format.any { head 404 }
    end
  end
end
