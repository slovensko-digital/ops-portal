class AddAttributesToIssuesDrafts < ActiveRecord::Migration[8.0]
  def up
    add_column :issues_drafts, :embed, :string
    add_column :issues_drafts, :map_zoom, :integer
    add_column :issues_drafts, :accuracy, :integer
    add_column :issues_drafts, :posted_at, :datetime
    add_column :issues_drafts, :published_at, :datetime
    add_column :issues_drafts, :front_page, :boolean
    add_column :issues_drafts, :mms, :boolean
    add_column :issues_drafts, :state, :integer
    add_column :issues_drafts, :soft_reject, :boolean
    add_column :issues_drafts, :owner_id, :integer
    add_column :issues_drafts, :new_owner_id, :integer
    add_column :issues_drafts, :modified_at, :datetime # mozno staci iba updated_at
    add_column :issues_drafts, :updated_by, :integer
    add_column :issues_drafts, :last_status_changed_at, :datetime
    add_column :issues_drafts, :responsibility_type, :integer
    add_column :issues_drafts, :responsibility, :integer
    add_column :issues_drafts, :mobile, :boolean
    add_column :issues_drafts, :ip, :inet
    add_column :issues_drafts, :secure, :string
    add_column :issues_drafts, :discussion_allowed, :boolean
    add_column :issues_drafts, :like_count, :integer
    add_column :issues_drafts, :comment_count_7d, :integer
    add_column :issues_drafts, :like_count_7d, :integer
    add_column :issues_drafts, :question, :boolean
    add_column :issues_drafts, :responsibility_set, :boolean
    add_column :issues_drafts, :responsibility_set_at, :datetime
    add_column :issues_drafts, :platform, :string
    add_column :issues_drafts, :reg_symbol, :string
    add_column :issues_drafts, :internal_state_id, :integer
    add_column :issues_drafts, :label_id, :integer
    add_column :issues_drafts, :note, :string
    add_column :issues_drafts, :posted_by_municipality_user_id, :integer
    add_column :issues_drafts, :manual, :boolean
    add_column :issues_drafts, :source_id, :integer
    add_column :issues_drafts, :organizational_unit_id, :integer
    add_column :issues_drafts, :ended_at, :datetime
    add_column :issues_drafts, :parent_id, :integer
    add_column :issues_drafts, :organizational_unit2_id, :integer
  end
end
