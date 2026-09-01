# spec/services/provider_service_spec.rb
require "rails_helper"

RSpec.describe ProviderService do
  before do
    # Stub all HTTP requests
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe ".init_transaction" do
    let(:params) do
      {
        amount: 1000,
        currency: "EUR",
        external_id: "unique_id_123"
      }
    end

    context "when provider responds successfully" do
      before do
        stub_request(:post, "https://provider.example.com/transactions/init")
          .with(
            body: { amount: 1000, currency: "EUR", id: "unique_id_123" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .to_return(
            status: 200,
            body: { transaction_id: "123", status: "pending" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns parsed response" do
        result = described_class.init_transaction(**params)
        expect(result).to eq({ "transaction_id" => "123", "status" => "pending" })
      end
    end

    context "when provider returns error" do
      before do
        stub_request(:post, "https://provider.example.com/transactions/init")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises ProviderError" do
        expect {
          described_class.init_transaction(**params)
        }.to raise_error(ProviderService::ProviderError, /Provider init failed: 500/)
      end
    end

    context "when provider returns invalid JSON" do
      before do
        stub_request(:post, "https://provider.example.com/transactions/init")
          .to_return(status: 200, body: "invalid json")
      end

      it "raises ProviderError" do
        expect {
          described_class.init_transaction(**params)
        }.to raise_error(ProviderService::ProviderError, /Invalid JSON response/)
      end
    end

    context "when network timeout occurs" do
      before do
        stub_request(:post, "https://provider.example.com/transactions/init")
          .to_timeout
      end

      it "raises ProviderError" do
        expect {
          described_class.init_transaction(**params)
        }.to raise_error(ProviderService::ProviderError, /HTTP request failed/)
      end
    end
  end

  describe ".authorize_transaction" do
    let(:transaction_id) { "123" }

    context "when authorization succeeds" do
      before do
        stub_request(:put, "https://provider.example.com/transactions/auth/#{transaction_id}")
          .to_return(
            status: 200,
            body: { status: "success" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns success status" do
        result = described_class.authorize_transaction(transaction_id)
        expect(result["status"]).to eq("success")
      end
    end

    context "when authorization fails" do
      before do
        stub_request(:put, "https://provider.example.com/transactions/auth/#{transaction_id}")
          .to_return(
            status: 200,
            body: { status: "failed" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns failed status" do
        result = described_class.authorize_transaction(transaction_id)
        expect(result["status"]).to eq("failed")
      end
    end

    context "when provider returns error" do
      before do
        stub_request(:put, "https://provider.example.com/transactions/auth/#{transaction_id}")
          .to_return(status: 400)
      end

      it "raises ProviderError" do
        expect {
          described_class.authorize_transaction(transaction_id)
        }.to raise_error(ProviderService::ProviderError)
      end
    end
  end
end
