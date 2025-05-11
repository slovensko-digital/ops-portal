class AnonymousUser
  def subscribed_to?(issue)
    false
  end

  def likes?(thing)
    false
  end

  def dislikes?(thing)
    false
  end

  def onboarded?
    false
  end

  def full_access?
    false
  end

  def can_edit?(thing)
    false
  end

  def municipality
    nil
  end
end
