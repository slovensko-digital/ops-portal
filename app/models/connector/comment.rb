# == Schema Information
#
# Table name: connector_comments
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  backoffice_external_id :string
#  triage_external_id     :integer
#
class Connector::Comment < ApplicationRecord
end
