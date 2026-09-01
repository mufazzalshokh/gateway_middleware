# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  # GET /transactions/auth/:id
  def auth
    transaction_id = params[:id]

    # Validate transaction ID format (security: prevent injection)
    unless transaction_id.match?(/\A[a-zA-Z0-9_-]+\z/)
      return render plain: "failed", status: :bad_request
    end

    # Find transaction in our database
    transaction = Transaction.find_by(provider_transaction_id: transaction_id)

    unless transaction
      return render plain: "failed", status: :not_found
    end

    # Call provider to authorize
    begin
      provider_response = ProviderService.authorize_transaction(transaction_id)

      # Update transaction status
      transaction.update!(status: provider_response["status"])

      # Check result
      if provider_response["status"] == "success"
        render plain: "success", status: :ok
      else
        render plain: "failed", status: :ok
      end
    rescue ProviderService::ProviderError => e
      Rails.logger.error("Authorization failed: #{e.message}")
      transaction.update(status: "error") rescue nil
      render plain: "failed", status: :service_unavailable
    end
  end
end
