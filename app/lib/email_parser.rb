class EmailParser
  REPLY_MARKERS = [
  # English: "On May 27, 2025, John <john@example.com> wrote:"
  /\bOn\s.+?<[^@>]+@[^>]+>\s+wrote:/i,

  # English (Gmail style): "On Mon, May 27, 2025 at 11:04 AM, John <john@example.com> wrote:"
  /\bOn\s\w{3},\s.+?<[^@>]+@[^>]+>\s+wrote:/i,

  # Slovak formal: "Dňa 27. mája 2025 napísal(a) Ján <jan@example.com>:"
  /\bD[ňn]a\s.+?nap[ií]sal\(a\)\s.+?<[^@>]+@[^>]+>:/i,

  # Slovak informal: "ut 27. 5. 2025 o 11:04 Ján <jan@example.com> napísal(a):"
  /\b(?:po|ut|st|št|pi|so|ne)\s+\d{1,2}\.\s*\d{1,2}\.\s*\d{4}\s+o\s+\d{1,2}:\d{2}\s+.+?<[^@>]+@[^>]+>\s*nap[ií]sal\(a\):/i,

  # Czech: "Dne 27. května 2025 napsal(a) Jan <jan@example.com>:"
  /\bDne\s.+?napsal\(a\)\s.+?<[^@>]+@[^>]+>:/i,

  # Hungarian: "2025. május 27., kedd 11:04-kor írta János <janos@example.com>:"
  /\d{4}\.\s?\w+\s\d{1,2}\.,?.*?írta\s.+?<[^@>]+@[^>]+>:/i,

  # Generic fallback: "Someone <someone@example.com> napísal(a):"
  /.+?<[^@>]+@[^>]+>\s*nap[ií]sal\(a\):/i,
  /.+?<[^@>]+@[^>]+>\s*wrote:/i,

  # Outlook-style header block (may span multiple lines, handle one line at a time)
  /^From:\s.+?<[^@>]+@[^>]+>$/i,
  /^Sent:\s.+$/i,
  /^To:\s.+$/i,
  /^Subject:\s.+$/i
]


  def self.parse_text(html)
    doc = Nokogiri::HTML(html)

    # Remove quoted content
    doc.css("blockquote, .gmail_quote, .yahoo_quoted, .WordSection1, #divRplyFwdMsg").each(&:remove)

    # Remove reply marker node and everything after it
    doc.css("div, p").each do |node|
      text = CGI.unescapeHTML(node.text.strip)
      if REPLY_MARKERS.any? { |regex| text.match?(regex) }
        current = node
        while current
          nxt = current.next_sibling
          current.remove
          current = nxt
        end
        break
      end
    end

    # What's left is likely the last message
    last_message = doc.at("body")&.text
    last_message = last_message.strip if last_message
    EmailReplyParser.read(last_message).visible_text
  end
end
