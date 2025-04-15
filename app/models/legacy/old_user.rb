class Legacy::OldUser < Legacy::GenericModel # name clash with Legacy::User
  self.table_name = "users"
end
