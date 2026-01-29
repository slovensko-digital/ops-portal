# == Schema Information
#
# Table name: users
#
#  id                               :bigint           not null, primary key
#  about                            :string
#  active                           :boolean
#  admin_name                       :string
#  anonymous                        :boolean          default(FALSE)
#  banned                           :boolean          default(FALSE)
#  birth                            :date
#  created_from_app                 :boolean          default(FALSE)
#  display_name                     :string
#  email                            :citext           not null
#  email_global_unsubscribe_token   :string           not null
#  email_notifiable                 :boolean          default(TRUE)
#  exp                              :integer
#  fcm_token                        :string
#  firstname                        :string
#  gdpr_accepted                    :boolean
#  gdpr_stats_accepted              :boolean          default(FALSE)
#  imported_at                      :datetime
#  lastname                         :string
#  login                            :string
#  newsletter_accepted              :boolean          default(FALSE), not null
#  onboarded                        :boolean          default(FALSE)
#  organization                     :boolean
#  password_hash                    :string
#  phone                            :string
#  phone_verification_attempted_at  :datetime
#  phone_verification_attempts      :integer          default(0), not null
#  phone_verification_code          :string
#  phone_verification_code_attempts :integer          default(0), not null
#  phone_verified                   :boolean          default(FALSE), not null
#  resident                         :boolean
#  sex                              :integer
#  signature                        :string
#  stats_comments_count             :integer          default(0)
#  stats_comments_percentile        :decimal(5, 4)    default(0.0)
#  stats_issues_count               :integer          default(0)
#  stats_issues_percentile          :decimal(5, 4)    default(0.0)
#  stats_verified_issues_count      :integer          default(0)
#  stats_verified_issues_percentile :decimal(5, 4)    default(0.0)
#  status                           :integer          default("unverified"), not null
#  timestamp                        :datetime
#  type                             :string
#  uuid                             :uuid             not null
#  verification                     :string
#  verified                         :boolean          default(FALSE)
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  city_id                          :integer
#  external_id                      :integer
#  legacy_id                        :integer
#  municipality_id                  :bigint
#  responsible_subject_id           :bigint
#  street_id                        :bigint
#
class User::ResponsibleSubject < User
  after_create do
    SyncUserResponsibleSubjectToTriageJob.perform_later(self)
  end

  validates :responsible_subject, presence: true
end
