class Cms::WebhooksController < ActionController::API
  before_action :authenticate

  def webhook
    if params[:post]
      # we care only about the first post
      if params[:post][:post_number] == 1
        Cms::ImportPageJob.perform_later(params[:post][:topic_id])
      end
    elsif params[:topic]
      Cms::ImportPageJob.perform_later(params[:topic][:id])
    elsif params[:category]
      category_ids = importing_category_ids
      # run import only for the category we are actually importing
      if category_ids.include?(params[:category][:id]) || category_ids.include?(params[:category][:parent_category_id])
        Cms::ImportCategoryJob.perform_later(params[:category][:id])
      end
    end
  end

  private

  def authenticate
    payload = request.raw_post
    header_signature = request.headers["X-Discourse-Event-Signature"]
    secret = ENV["DISCOURSE_WEBHOOK_SECRET"]

    render status: :unauthorized, json: nil and return unless header_signature&.start_with?("sha256=")

    expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, header_signature)
  end

  def importing_category_ids
    ENV["DISCOURSE_IMPORT_CATEGORY_IDS"].split(",").map(&:to_i)
  end
end
