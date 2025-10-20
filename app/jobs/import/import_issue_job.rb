module Import
  class ImportIssueJob < ApplicationJob
    queue_with_priority 100

    ARCHIVE_THRESHOLD = Date.parse("2020-01-01").beginning_of_day

    include ImportMethods

    def perform(
      legacy_record,
      import_photos_job: Issues::ImportIssuePhotosJob,
      import_updates_job: Issues::ImportIssueUpdatesJob,
      import_comments_job: Issues::ImportIssueCommentsJob,
      import_communications_job: Issues::ImportIssueCommunicationsJob,
      import_subscriptions_job: Issues::ImportIssueSubscriptionsJob,
      import_likes_job: Issues::ImportIssueLikesJob
    )
      municipality = Municipality.find_by(legacy_id: legacy_record.mesto)
      municipality_district = municipality&.municipality_districts.find_by(legacy_id: legacy_record.mestska_cast)

      legacy_subtype = ::Issues::Subtype.find_by(legacy_id: legacy_record.kategoria)
      legacy_subcategory = legacy_subtype&.subcategory || ::Issues::Subcategory.find_by(legacy_id: legacy_record.kategoria)
      legacy_category = legacy_subcategory&.category || ::Issues::Category.find_by(legacy_id: legacy_record.kategoria)
      category, subcategory, subtype = CategoryMapper.map_legacy_categories_to_new(legacy_category, legacy_subcategory, legacy_subtype)

      owner = if legacy_record.riesitel_new.nil? || legacy_record.riesitel_new == 0
        Legacy::User.find_or_create_agent(legacy_record.riesitel)
      else
        Legacy::User.find_or_create_agent(legacy_record.riesitel_new)
      end
      backoffice_owners = Legacy::Alerts::MunicipalityUser.where(alert_id: legacy_record.id).order(:id)

      state = ::Issues::State.find_by(legacy_id: legacy_record.status)
      archived_state = nil

      if convert_timestamp_value(legacy_record.posted_time) < ARCHIVE_THRESHOLD ||
         municipality.archived? || municipality_district&.archived?
        archived_state = state
        state = ::Issues::State.find_by(key: "archived")
      end

      issue = Issue.find_or_create_by(
        id: legacy_record.id,
        legacy_id: legacy_record.id,
        address_city: Municipality.find_by(legacy_id: legacy_record.mesto)&.name,
        address_region: Municipality.find_by(legacy_id: legacy_record.mesto)&.district&.name,
        address_street: Street.find_by(legacy_id: legacy_record.ulica)&.name,
        address_municipality: MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast)&.name,
        anonymous: legacy_record.anonymous,
        description: legacy_record.description,
        discussion_closed: legacy_record.allow_discussion == 0,
        latitude: legacy_record.map_x,
        legacy_data: {
          legacy_category_id: legacy_category.legacy_id,
          legacy_subcategory_id: legacy_subcategory.legacy_id,
          legacy_subtype_id: legacy_subtype.legacy_id,
          embed: legacy_record.embed,
          map_zoom: legacy_record.map_zoom,
          accuracy: legacy_record.accuracy,
          published_at: legacy_record.published_time,
          front_page: legacy_record.titulka,
          mms: legacy_record.mms,
          soft_reject: legacy_record.soft_reject,
          owner_id: legacy_record.riesitel,
          new_owner_id: legacy_record.riesitel_new,
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
          legacy_responsible_subject_id: legacy_record.zodpovednost,
          legacy_municipality_district_id: legacy_record.mestska_cast,
          backoffice_owner_legacy_id: backoffice_owners&.last&.municipality_user_id,
          other_backoffice_owners_legacy_ids: backoffice_owners[0..-2]&.map(&:municipality_user_id)
        },
        longitude: legacy_record.map_y,
        title: legacy_record.heading,
        created_at: convert_timestamp_value(legacy_record.posted_time),
        author: Legacy::User.find_or_create_user(legacy_record.posted_by),
        owner: owner,
        category: category,
        subcategory: subcategory,
        subtype: subtype,
        municipality: municipality,
        municipality_district: municipality_district,
        responsible_subject: Legacy::ResponsibleSubject.find_or_create_responsible_subject(legacy_record.zodpovednost),
        state: state,
        archived_state: archived_state
      ).tap do |issue|
        issue.imported_at = Time.now
        issue.updated_at = convert_timestamp_value(legacy_record.modified_time) if legacy_record.modified_time
        issue.save!
      end

      import_photos_job.perform_later(issue: issue)
      import_updates_job.perform_later(issue: issue)
      import_comments_job.perform_later(issue: issue)
      import_communications_job.perform_later(issue: issue)
      # import_subscriptions_job.perform_later(issue: issue) # TODO rather run after the whole import
      import_likes_job.perform_later(issue: issue)
    end
  end
end
