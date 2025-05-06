# == Schema Information
#
# Table name: media_images
#
#  id        :integer          unsigned, not null, primary key
#  href      :string(70)       not null
#  original  :string(255)
#  position  :integer          default(1), unsigned, not null
#  thumbnail :string(255)
#  alert_id  :integer          unsigned, not null
#
class Legacy::Alerts::MunicipalityUser < Legacy::GenericModel
  self.table_name = "alerts_municipality_users"
end
