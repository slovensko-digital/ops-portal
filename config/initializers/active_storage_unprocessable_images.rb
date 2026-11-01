Rails.application.config.to_prepare do
  # A blob whose bytes are not a format vips can read (e.g. a non-image renamed to .png)
  # is not a server error, respond with 422 instead of raising.
  ActiveStorage::Representations::BaseController.rescue_from Vips::Error do
    head :unprocessable_entity
  end
end
