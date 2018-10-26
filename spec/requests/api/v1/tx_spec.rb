require 'rails_helper'

RSpec.describe "Transaction signing" do

  describe "GET /api/v1/tx/fee" do
    it "returns the fee required for the server to sign a tx" do
      get("/api/v1/tx/fee")

      expect(response).to be_successful

      parsed_response = JSON.parse(response.body).with_indifferent_access
      expect(parsed_response[:fee_in_stroops]).to eq ENV["FEE_IN_STROOPS"].to_i
    end
  end

end
