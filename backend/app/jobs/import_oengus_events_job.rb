class ImportOengusEventsJob < ApplicationJob
  WINDOW = 12.months

  def perform
    summary = Events::Import.new(source: Events::Sources::Oengus.new)
      .call(from: Time.current, to: WINDOW.from_now)

    Rails.logger.info("[ImportOengusEventsJob] #{summary}")
  end
end
