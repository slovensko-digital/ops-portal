class MakeBooleansNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_default :issues_updates, :published, from: nil, to: false
    change_column_default :responsible_subjects, :pro, from: nil, to: false
    change_column_default :responsible_subjects_types, :active, from: nil, to: false
    change_column_default :responsible_subjects_users, :gdpr_accepted, from: nil, to: false
    change_column_default :responsible_subjects_users, :tooltips, from: nil, to: false

    change_column_null :connector_tenants, :migrate_legacy_labels, false
    change_column_null :issues, :discussion_closed, false
    change_column_null :issues_categories, :catch_all, false
    change_column_null :issues_comments, :hidden, false
    change_column_null :issues_drafts, :latlon_from_exif, false
    change_column_null :issues_updates, :published, false
    change_column_null :issues_updates, :confirmed, false
    change_column_null :issues_updates, :hidden, false
    change_column_null :municipality_districts, :archived, false
    change_column_null :municipality_districts, :active, false
    change_column_null :responsible_subjects, :pro, false
    change_column_null :responsible_subjects_types, :active, false
    change_column_null :responsible_subjects_users, :gdpr_accepted, false
    change_column_null :responsible_subjects_users, :tooltips, false
    change_column_null :streets, :whitelisted, false
    change_column_null :users, :banned, false
    change_column_null :users, :anonymous, false
    change_column_null :users, :created_from_app, false
    change_column_null :users, :verified, false
    change_column_null :users, :email_notifiable, false
    change_column_null :users, :gdpr_stats_accepted, false
    change_column_null :users, :onboarded, false
  end
end
