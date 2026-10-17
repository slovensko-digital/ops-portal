class SetNilBooleansToFalse < ActiveRecord::Migration[8.1]
  def up
    Connector::Tenant.where(migrate_legacy_labels: nil).update_all(migrate_legacy_labels: false)
    Issue.where(discussion_closed: nil).update_all(discussion_closed: false)
    Issues::Category.where(catch_all: nil).update_all(catch_all: false)
    Issues::Comment.where(hidden: nil).update_all(hidden: false)
    Issues::Draft.where(latlon_from_exif: nil).update_all(latlon_from_exif: false)
    Issues::Update.where(published: nil).update_all(published: false)
    Issues::Update.where(confirmed: nil).update_all(confirmed: false)
    Issues::Update.where(hidden: nil).update_all(hidden: false)
    MunicipalityDistrict.where(archived: nil).update_all(archived: false)
    MunicipalityDistrict.where(active: nil).update_all(active: false)
    ResponsibleSubject.where(pro: nil).update_all(pro: false)
    ResponsibleSubjects::Type.where(active: nil).update_all(active: false)
    ResponsibleSubjects::User.where(gdpr_accepted: nil).update_all(gdpr_accepted: false)
    ResponsibleSubjects::User.where(tooltips: nil).update_all(tooltips: false)
    Street.where(whitelisted: nil).update_all(whitelisted: false)
    User.where(banned: nil).update_all(banned: false)
    User.where(anonymous: nil).update_all(anonymous: false)
    User.where(created_from_app: nil).update_all(created_from_app: false)
    User.where(verified: nil).update_all(verified: false)
    User.where(email_notifiable: nil).update_all(email_notifiable: false)
    User.where(gdpr_stats_accepted: nil).update_all(gdpr_stats_accepted: false)
    User.where(onboarded: nil).update_all(onboarded: false)
  end

  def down
  end
end
