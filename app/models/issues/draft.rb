class Issues::Draft < ApplicationRecord
  has_many_attached :photos do |photo|
    photo.variant :thumb, resize_to_limit: [ 320, 240 ], preprocessed: true
  end

  validates_presence_of :photos, on: :photos_step
  validates_presence_of :title, :description, on: :details_step

  def confirm
    # TODO create issue and delete draft
  end

  def schedule_calculate_suggestions
    ::Issues::Draft::GenerateSuggestionsJob.perform_later(self)
  end

  def geo
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  def load_geo_from_exif(photo)
    begin
      d = Exif::Data.new(photo.blob.download)
    rescue Exif::NotReadable
      return
    end

    gps = d[:gps]
    if gps
      self.latitude = gps_to_float(gps[:gps_latitude])
      self.longitude = gps_to_float(gps[:gps_longitude])
    end
  end

  def update_with_context(attributes, context)
    # TODO move to AR monkey-patch
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end

  def pick_suggestion(suggestions_params)
    assign_attributes(suggestions_params)
    if picked_suggestion_index == -1
      self.title = self.description = nil
      self.categories = []
    else
      self.title, self.description, self.category, self.subcategory, self.subtype = suggestions[picked_suggestion_index]&.values_at("title", "description", "category", "subcategory", "subtype")
    end
    save(context: :suggestions_step)
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end
end
