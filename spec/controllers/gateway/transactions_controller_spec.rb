# spec/controllers/gateway/transactions_controller_spec.rb
require 'rails_helper'

RSpec.describe Gateway::TransactionsController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        amount: 1000,
        currency: 'EUR',
        id: 'unique_id_123'
      }
    end

    before do
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    context 'with valid parameters' do
      before do
        stub_request(:post, 'https://provider.example.com/transactions/init')
          .to_return(
            status: 200,
            body: { transaction_id: '123', status: 'pending' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
      end

      it 'returns redirect_url' do
        post :create, params: valid_params
        
        json_response = JSON.parse(response.body)
        expect(json_response['redirect_url']).to include('/transactions/auth/123')
        expect(response).to have_http_status(:created)
      end

      it 'stores transaction with correct data' do
        post :create, params: valid_params
        
        transaction = Transaction.last
        expect(transaction.external_id).to eq('unique_id_123')
        expect(transaction.provider_transaction_id).to eq('123')
        expect(transaction.amount).to eq(1000)
        expect(transaction.currency).to eq('EUR')
        expect(transaction.status).to eq('pending')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing amount' do
        post :create, params: { currency: 'EUR', id: 'test' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error for zero amount' do
        post :create, params: { amount: 0, currency: 'EUR', id: 'test' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error for missing currency' do
        post :create, params: { amount: 1000, id: 'test' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error for missing id' do
        post :create, params: { amount: 1000, currency: 'EUR' }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when provider is unavailable' do
      before do
        stub_request(:post, 'https://provider.example.com/transactions/init')
          .to_timeout
      end

      it 'returns service unavailable error' do
        post :create, params: valid_params
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'does not create transaction' do
        expect {
          post :create, params: valid_params
        }.not_to change(Transaction, :count)
      end
    end

    context 'when duplicate external_id is provided' do
      before do
        stub_request(:post, 'https://provider.example.com/transactions/init')
          .to_return(
            status: 200,
            body: { transaction_id: '123', status: 'pending' }.to_json
          )
        
        # Create first transaction
        post :create, params: valid_params
      end

      it 'returns unprocessable entity' do
        stub_request(:post, 'https://provider.example.com/transactions/init')
          .to_return(
            status: 200,
            body: { transaction_id: '456', status: 'pending' }.to_json
          )
        
        post :create, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
