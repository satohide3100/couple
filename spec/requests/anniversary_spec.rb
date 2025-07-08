require 'rails_helper'

RSpec.describe "Anniversaries", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/anniversary/index"
      expect(response).to have_http_status(:success)
    end
  end

end
