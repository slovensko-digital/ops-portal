class Cms::PagesController < ApplicationController
  # /:category_slug
  # /:page_slug
  # /:category_slug/:page_slug
  def index
    slugs = params[:path].split("/")

    root_category = Cms::Category.find(ENV["CMS_ROOT_CATEGORY_ID"])
    result = Cms::Page.find_by_path(root_category, slugs)

    return raise_not_found unless result

    @category, @page = result
    if @page
      render :show
    else
      @pages = @category.pages.published.order(created_at: :desc).page(params[:page]).per(12)
    end
  end

  private

  def raise_not_found
    raise ActionController::RoutingError, "Not Found"
  end
end
