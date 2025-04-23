module Legacy
  class GenericModel < ::ApplicationRecord
    self.abstract_class = true

    connects_to database: { reading: :legacy_db }

    def self.default_role
      :reading
    end

    def readonly?
      true
    end
  end
end
