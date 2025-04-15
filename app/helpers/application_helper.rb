module ApplicationHelper
  def format_date(datetime)
    datetime.strftime("%d.%m.%Y")
  end

  def ops_paginate(scope)
    config = if scope.first_page?
      { window: 1, left: 3, right: 1 }
    elsif scope.last_page?
      { window: 1, left: 1, right: 3 }
    else
      { window: 1, outer_window: 1 }
    end

    raw(
      paginate scope, **config.merge(theme: "ops")
    )
  end
end
