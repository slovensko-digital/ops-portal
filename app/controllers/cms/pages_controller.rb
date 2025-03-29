class Cms::PagesController < ApplicationController
  # /:category_slug
  # /:page_slug
  # /:category_slug/:page_slug
  def index
    slugs = params[:cms_slugs].split("/")

    root_category = Cms::Category.find_by(id: ENV["CMS_ROOT_CATEGORY_ID"])

    raise(Exception.new("Missing required cms root category")) if root_category.nil?

    result = Cms::Page.find_by_path(root_category, slugs)

    if result.nil?
      raise_not_found
    else
      @category, @page = result
    end

    if @page
      render "cms/pages/show"
    else
      @pages = load_pages(@category)
    end
  end

  private

  def load_pages(category)
    category.pages.published.order(created_at: :desc).page(params[:page]).per(12)
  end

  def load_page(category, slug)
    category.pages.published.find_by(slug: slug)
  end

  def raise_not_found
    raise ActionController::RoutingError.new("Not Found in Cms")
  end
end
