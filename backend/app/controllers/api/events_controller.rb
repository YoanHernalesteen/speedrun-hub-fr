module Api
  class EventsController < ApplicationController
    def index
      authorize Event
      events = policy_scope(Event).upcoming

      render json: { events: events.map { |event| EventSerializer.new(event).as_json } }
    end

    def show
      event = policy_scope(Event).find(params[:id])
      authorize event

      render json: { event: EventSerializer.new(event).as_detail_json }
    end
  end
end
