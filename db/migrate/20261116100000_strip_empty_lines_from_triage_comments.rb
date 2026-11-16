class StripEmptyLinesFromTriageComments < ActiveRecord::Migration[8.1]
  # Triage tags like [[ops portal]] sit on a line of their own. The portal removed the tag but kept
  # the empty line, so comments from Triage started with blank lines. ZammadApiClient now drops them
  # for new comments; this cleans up the stored ones. The patterns are copied, not referenced, so the
  # migration keeps working if the client changes.
  EMPTY_LINE = %r{\s|&nbsp;|<br\s*/?>|<(div|p)\b[^>]*>(?:\s|&nbsp;|<br\s*/?>)*</\1>}i
  LEADING_EMPTY_LINES = /\A(?:#{EMPTY_LINE})+/
  TRAILING_EMPTY_LINES = /(?:#{EMPTY_LINE})+\z/
  LEADING_BREAKS = %r{\A(<(?:div|p)\b[^>]*>)(?:\s|&nbsp;|<br\s*/?>)+}i
  TRAILING_BREAKS = %r{(?:\s|&nbsp;|<br\s*/?>)+(</(?:div|p)>)\z}i

  class Comment < ActiveRecord::Base
    self.table_name = "issues_comments"
    self.inheritance_column = nil
  end

  def up
    Comment.where.not(triage_external_id: nil).where.not(text: nil).find_each do |comment|
      text = comment.text
        .sub(LEADING_EMPTY_LINES, "").sub(TRAILING_EMPTY_LINES, "")
        .sub(LEADING_BREAKS, "\\1").sub(TRAILING_BREAKS, "\\1")
        .strip
      comment.update_column(:text, text) if text != comment.text.strip
    end
  end

  def down
  end
end
