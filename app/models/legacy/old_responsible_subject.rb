class Legacy::OldResponsibleSubject < Legacy::GenericModel # name clash with Legacy::ResponsibleSubject
  self.table_name = "zodpovednost"
end
