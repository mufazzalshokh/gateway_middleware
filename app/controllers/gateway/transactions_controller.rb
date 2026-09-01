# app/controllers/gateway/transactions_controller.rb
module Gateway
  class TransactionsController < ApplicationController
    # Disable CSRF for API endpoint (Gateway is external system)
    skip_before_action :verify_authenticity_token

    # POST /gateway/transactions
    def create
      # Validate input
      unless valid_params?
        return render json: { error: "Invalid parameters" }, status: :bad_request
      end

      # Call provider to initialize transaction
      begin
        provider_response = ProviderService.init_transaction(
          amount: params[:amount],
          currency: params[:currency],
          external_id: params[:id]
        )
      rescue ProviderService::ProviderError => e
        Rails.logger.error("Provider error: #{e.message}")
        return render json: { error: "Provider unavailable" }, status: :service_unavailable
      end

      # Save transaction in our database
      transaction = Transaction.create!(
        external_id: params[:id],
        provider_transaction_id: provider_response["transaction_id"],
        amount: params[:amount],
        currency: params[:currency],
        status: provider_response["status"]
      )

      # Build our redirect URL
      redirect_url = transactions_auth_url(transaction.provider_transaction_id)

      # Return to Gateway
      render json: { redirect_url: redirect_url }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def valid_params?
      params[:amount].present? &&
        params[:currency].present? &&
        params[:id].present? &&
        params[:amount].to_i > 0
    end
  end
end
