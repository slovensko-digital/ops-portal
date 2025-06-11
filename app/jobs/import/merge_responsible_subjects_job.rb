class Import::MergeResponsibleSubjectsJob < ApplicationJob
  def perform(main_responsible_subject:, other_responsible_subjects_ids:)
    Issue.where(responsible_subject_id: other_responsible_subjects_ids).each do |issue|
      issue.update!(responsible_subject: main_responsible_subject)
    end

    ResponsibleSubjects::User.where(responsible_subject_id: other_responsible_subjects_ids).update_all(responsible_subject_id: main_responsible_subject)

    ResponsibleSubjects::OrganizationUnit.where(responsible_subject_id: other_responsible_subjects_ids).update_all(responsible_subject_id: main_responsible_subject)

    ResponsibleSubject.where(id: other_responsible_subjects_ids).update_all(active: false)
  end
end
