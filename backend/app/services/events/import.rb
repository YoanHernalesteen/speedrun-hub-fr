module Events
  # Synchronizes the events of one source with the database:
  # creates or updates every fetched event, then deletes the source's
  # events that are not ended yet and were not returned anymore.
  class Import
    def initialize(source:)
      @source = source
    end

    def call(from:, to:)
      fetched = @source.fetch(from:, to:)
      summary = { created: 0, updated: 0, deleted: 0, skipped: 0 }

      Event.transaction do
        fetched.each { |attributes| summary[save(attributes)] += 1 }
        summary[:deleted] = delete_missing(fetched.map { |attributes| attributes[:external_id] })
      end

      summary
    end

    private

    def save(attributes)
      event = Event.find_or_initialize_by(source: @source.name, external_id: attributes[:external_id])
      status = event.new_record? ? :created : :updated
      event.assign_attributes(attributes.merge(synced_at: Time.current))

      if event.save
        status
      else
        Rails.logger.warn("[Events::Import] Skipped #{@source.name}/#{attributes[:external_id]}: " \
          "#{event.errors.full_messages.to_sentence}")
        :skipped
      end
    end

    # Invalid events count as returned: their previous version is kept.
    def delete_missing(returned_ids)
      Event.not_ended
        .where(source: @source.name)
        .where.not(external_id: returned_ids)
        .delete_all
    end
  end
end
