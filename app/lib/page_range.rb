# Parses and applies the `page` query param. Besides plain page numbers
# it supports ranges like "1-4".

module PageRange
  # Paginates the scope honoring the raw `page` query param. Loads the
  # whole range in a single query. Returns [records, pagination], where
  # pagination is a Kaminari page object for the last loaded page.
  def self.paginate(scope, page_param, per_page)
    first_page, last_page = parse(page_param)
    records = scope.offset((first_page - 1) * per_page).limit(per_page * (last_page - first_page + 1)).to_a
    [ records, scope.page(last_page).per(per_page) ]
  end

  # Returns [first_page, last_page], both >= 1.
  def self.parse(param)
    case param.to_s
    when /\A(\d+)-(\d+)\z/
      first = Regexp.last_match(1).to_i
      last = Regexp.last_match(2).to_i
      first = 1 if first < 1
      last = first if last < first
      [ first, last ]
    when /\A(\d+)\z/
      page = Regexp.last_match(1).to_i
      page = 1 if page < 1
      [ page, page ]
    else
      [ 1, 1 ]
    end
  end
end
