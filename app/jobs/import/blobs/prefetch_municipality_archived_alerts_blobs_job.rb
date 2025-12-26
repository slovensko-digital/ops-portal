module Import
  class Blobs::PrefetchMunicipalityArchivedAlertsBlobsJob < ApplicationJob
    queue_with_priority 100

    def perform(
      municipality:,
      import_till: Date.parse("2020-01-01").beginning_of_day
    )
      Legacy::Alert.where(mesto: municipality.legacy_id)
                   .where(is_manual: 0)
                   .where("posted_time < ?", import_till.to_i).find_in_batches do |group|
        group.each do |legacy_alert|
          Blobs::PrefetchAlertBlobsJob.perform_later(legacy_alert.id)
        end
      end
    end
  end
end
