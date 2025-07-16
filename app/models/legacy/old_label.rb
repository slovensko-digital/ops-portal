class Legacy::OldLabel < Legacy::GenericModel # name clash with Legacy::Label
  self.table_name = "labels"
end
