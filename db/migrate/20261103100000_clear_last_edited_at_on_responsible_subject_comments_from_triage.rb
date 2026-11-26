class ClearLastEditedAtOnResponsibleSubjectCommentsFromTriage < ActiveRecord::Migration[8.1]
  # Triage::CreateNewPortalActivityFromTriageJob attached images after create!, so the second save
  # stamped last_edited_at right after created_at and the comment showed as edited (issue #92).
  # Those comments were stamped within a second. A responsible subject who edits a comment on the
  # portal does it later, so those keep last_edited_at.
  def up
    execute <<~SQL
      UPDATE issues_comments
      SET last_edited_at = NULL
      WHERE type = 'Issues::ResponsibleSubjectComment'
        AND triage_external_id IS NOT NULL
        AND last_edited_at IS NOT NULL
        AND last_edited_at - created_at < interval '2 seconds';
    SQL
  end

  def down
  end
end
