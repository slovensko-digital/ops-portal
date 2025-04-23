module SearchEngine
  def self.new(**kwargs) # faux constructor
    SearchEngine::Engine.new(**kwargs)
  end
end
