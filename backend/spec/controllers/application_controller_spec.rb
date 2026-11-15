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

  describe "when an action forgets to call authorize" do
    controller do
      def show
        render json: {}
      end
    end

    it "raises instead of responding" do
      expect { get :show, params: { id: 1 } }.to raise_error(Pundit::AuthorizationNotPerformedError)
    end
  end

  describe "when an index forgets to scope its records" do
    controller do
      def index
        authorize Event
        render json: {}
      end
    end

    it "raises instead of responding" do
      expect { get :index }.to raise_error(Pundit::PolicyScopingNotPerformedError)
    end
  end
end
