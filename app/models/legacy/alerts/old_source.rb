class Legacy::Alerts::OldSource < Legacy::GenericModel # name clash with Legacy::Alerts::Source
  self.table_name = "sources"
end
