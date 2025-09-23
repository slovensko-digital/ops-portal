module Connector
  class SubtaskParser
    SubtaskData = Struct.new(:user_id, :title, :due_date, :line_content, keyword_init: true)

    # HTML Format: <a ... data-mention-user-id="..." ...>Username</a> - Title text [- DD.MM.YYYY]
    HTML_SUBTASK_PATTERN = /<a[^>]+data-mention-user-id="(?<user_id>\d+)"[^>]*>(?<assignee>[^<]+)<\/a>[^-]*-\s*(?<title>.+?)(?:\s*-\s*(?<due_date>\d{1,2}\.\d{1,2}\.\d{4}))?(?:<div>|<br>|$)/i
    SUBTASK_ARTICLE_TAG = "[[podulohy]]"

    def self.has_subtasks?(body)
      body.to_s.include?(SUBTASK_ARTICLE_TAG)
    end

    def self.parse_subtasks(body)
      return [] unless has_subtasks?(body)

      subtask_section = body.to_s.split(SUBTASK_ARTICLE_TAG).last.to_s
      subtask_section.split(/<br\s*\/?>/).map(&:strip).reject(&:empty?).filter_map do |line|
        parse_line(line)
      end
    end

    private

    def self.parse_line(line)
      match = line.match(HTML_SUBTASK_PATTERN)
      return unless match

      due_date = nil
      if match[:due_date]
        begin
          due_date = Date.strptime(match[:due_date], "%d.%m.%Y")
        rescue ArgumentError
          return
        end
      end

      SubtaskData.new(
        user_id: match[:user_id].strip,
        title: match[:title].strip,
        due_date: due_date,
        line_content: line
      )
    end
  end
end
