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
      pages = @category.pages.published
                      .order(created_at: :desc)

      @top_pages = pages.where("? = ANY(tags)", "top")
                        .limit(2)

      excluded_ids = @top_pages.ids

      @hero_pages = pages.where.not(id: excluded_ids)
                         .limit(3)

      excluded_ids += @hero_pages.ids

      @pages = pages.where.not(id: excluded_ids)
                    .page(params[:page])
                    .per(8)
    end
  end

  private

  def raise_not_found
    raise ActionController::RoutingError, "Not Found"
  end
end
