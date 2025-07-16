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
  /^Subject:\s.+$/i,

  # Slovak Outlook-style header block
  /^Od:\s.+?<[^@>]+@[^>]+>$/i,
  /^Odoslané:\s.+$/i,
  /^Komu:\s.+$/i,
  /^Predmet:\s.+$/i
]


  def self.parse_text(html)
    doc = Nokogiri::HTML(html)

    # Remove quoted content
    doc.css("blockquote, .gmail_quote, .yahoo_quoted, .WordSection1, #divRplyFwdMsg").each(&:remove)

    # Remove everything after signature marker if present
    sig_marker = doc.at_css(".js-signatureMarker")
    if sig_marker
      current = sig_marker
      parent = current.parent
      while parent && parent.element?
        current = current.next_sibling
        # remove all current's next siblings
        while current
          nxt = current.next_sibling
          current.remove
          current = nxt
        end
        # move to removing parent's next siblings
        current = parent
        parent = parent.parent
      end
      # Remove the marker itself
      sig_marker.remove
    end

    # Remove reply marker node and everything after it (search all elements)
    doc.traverse do |node|
      next unless node.element?
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

    # Remove tables that contain both a mailto: link and a www.something.sk link
    doc.css("table").each do |table|
      has_mailto = table.css('a[href^="mailto:"]').any?
      has_www_sk = table.css('a[href*="www."][href*=".sk"]').any?
      if has_mailto && has_www_sk
        table.remove
      end
    end

    # What's left is likely the last message
    last_message = doc.at("body")&.text
    last_message = last_message.strip if last_message

    # Normalize whitespace: remove non-breaking spaces and collapse blank lines
    last_message = last_message.gsub("\u00A0", " ").gsub(/\r\n?/, "\n")
    last_message = last_message.lines.map(&:rstrip).join("\n")
    last_message = last_message.gsub(/\n{3,}/, "\n\n").strip

    EmailReplyParser.read(last_message).visible_text
  end
end
