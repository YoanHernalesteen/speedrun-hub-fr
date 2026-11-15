require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      raise Pundit::NotAuthorizedError
    end
  end

  describe "when an action is not authorized" do
    it "responds with 403 and a JSON error" do
      get :index

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("error" => "forbidden")
    end
  end
end
