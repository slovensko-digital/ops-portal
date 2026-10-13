class SetNilBooleansToFalse < ActiveRecord::Migration[8.1]
  COLUMNS = {
    connector_tenants: %i[migrate_legacy_labels],
    issues: %i[discussion_closed],
    issues_categories: %i[catch_all],
    issues_comments: %i[hidden],
    issues_drafts: %i[latlon_from_exif],
    issues_updates: %i[published confirmed hidden],
    municipality_districts: %i[archived active],
    responsible_subjects: %i[pro],
    responsible_subjects_types: %i[active],
    responsible_subjects_users: %i[gdpr_accepted tooltips],
    streets: %i[whitelisted],
    users: %i[banned anonymous created_from_app verified email_notifiable gdpr_stats_accepted onboarded]
  }

  def up
    COLUMNS.each do |table, columns|
      model = Class.new(ActiveRecord::Base) { self.table_name = table }

      columns.each do |column|
        model.where(column => nil).update_all(column => false)
      end
    end
  end

  def down
  end
end
