module Import
  class ImportIssueJob < ApplicationJob
    include ImportMethods

    def perform(
      legacy_record,
      import_photos_job: Issues::ImportIssuePhotosJob,
      import_updates_job: Issues::ImportIssueUpdatesJob,
      import_comments_job: Issues::ImportIssueCommentsJob,
      import_communications_job: Issues::ImportIssueCommunicationsJob,
      import_likes_job: Issues::ImportIssueLikesJob
    )
      subtype = ::Issues::Subtype.find_by(legacy_id: legacy_record.kategoria)
      subcategory = subtype&.subcategory || ::Issues::Subcategory.find_by(legacy_id: legacy_record.kategoria)
      category = subcategory&.category || ::Issues::Category.find_by(legacy_id: legacy_record.kategoria)
      owner = if legacy_record.riesitel_new.nil? || legacy_record.riesitel_new == 0
        Legacy::User.find_or_create_agent(legacy_record.riesitel)
      else
        Legacy::User.find_or_create_agent(legacy_record.riesitel_new)
      end

      issue = Issue.find_or_create_by!(
        legacy_id: legacy_record.id,
        address_city: Municipality.find_by(legacy_id: legacy_record.mesto)&.name,
        address_region: Municipality.find_by(legacy_id: legacy_record.mesto)&.district&.name,
        address_street: Street.find_by(legacy_id: legacy_record.ulica)&.name,
        address_municipality: MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast)&.name,
        anonymous: legacy_record.anonymous,
        description: legacy_record.description,
        latitude: legacy_record.map_x,
        legacy_data: {
          embed: legacy_record.embed,
          map_zoom: legacy_record.map_zoom,
          accuracy: legacy_record.accuracy,
          published_at: legacy_record.published_time,
          front_page: legacy_record.titulka,
          mms: legacy_record.mms,
          soft_reject: legacy_record.soft_reject,
          owner_id: legacy_record.riesitel, # TODO nevieme referencia na ktory model by toto mala byt
          new_owner_id: legacy_record.riesitel_new, # TODO nevieme referencia na ktory model by toto mala byt
          modified_at: legacy_record.modified_time, # TODO nestaci updated_at?
          updated_by_id: legacy_record.modified_by, # TODO overit na ktory model je toto referencia
          state_changed_at: legacy_record.last_status_change_time,
          street_legacy_id: legacy_record.ulica,
          responsible_subject_type_id: legacy_record.zodpovednost_typ,
          mobile: legacy_record.mobile,
          ip: legacy_record.ip,
          secure: legacy_record.secure,
          discussion_allowed: legacy_record.allow_discussion,
          like_count: legacy_record.like_count,
          comment_count_7d: legacy_record.comment_count_7d,
          like_count_7d: legacy_record.like_count_7d,
          question: legacy_record.is_type_question,
          responsibility_set: legacy_record.is_responsibility_set,
          responsibility_set_at: legacy_record.responsibility_set_date,
          platform: legacy_record.platform,
          reg_symbol: legacy_record.reg_number,
          internal_state_id: legacy_record.internal_state_id,
          label_id: legacy_record.label_id,
          note: legacy_record.note,
          posted_by_municipality_user_id: legacy_record.posted_by_municipality_user,
          manual: legacy_record.is_manual,
          source_id: legacy_record.source_id,
          organizational_unit_id: legacy_record.organizational_unit_id,
          ended_at: legacy_record.end_date,
          parent_id: legacy_record.parent_id,
          organization_unit_id2: legacy_record.organizational_unit_id2,
          legacy_responsible_subject_id: legacy_record.zodpovednost
        },
        longitude: legacy_record.map_y,
        title: legacy_record.heading,
        created_at: convert_timestamp_value(legacy_record.posted_time),
        author: Legacy::User.find_or_create_user(legacy_record.posted_by),
        owner: owner,
        category: category,
        subcategory: subcategory,
        subtype: subtype,
        municipality: Municipality.find_by(legacy_id: legacy_record.mesto),
        municipality_district: MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast),
        responsible_subject: Legacy::ResponsibleSubject.find_or_create_responsible_subject(legacy_record.zodpovednost),
        state: ::Issues::State.find_by(legacy_id: legacy_record.status)
      ).tap do |issue|
        issue.imported_at = Time.now
        issue.save!
      end

      import_photos_job.perform_later(issue: issue)
      import_updates_job.perform_later(issue: issue)
      import_comments_job.perform_later(issue: issue)
      import_communications_job.perform_later(issue: issue)
      import_likes_job.perform_later(issue: issue)
    end
  end
end
