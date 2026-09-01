# app/services/provider_service.rb
class ProviderService
  include HTTParty
  base_uri ENV.fetch("PROVIDER_BASE_URL", "https://provider.example.com")

  class ProviderError < StandardError; end

  # Initialize a transaction with the provider
  def self.init_transaction(amount:, currency:, external_id:)
    response = post("/transactions/init",
      body: {
        amount: amount,
        currency: currency,
        id: external_id
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV.fetch('PROVIDER_API_KEY', 'test_key')}"
      },
      timeout: 10
    )

    raise ProviderError, "Provider init failed: #{response.code}" unless response.success?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ProviderError, "Invalid JSON response: #{e.message}"
  rescue HTTParty::Error, Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
    raise ProviderError, "HTTP request failed: #{e.message}"
  end

  # Authorize a transaction with the provider
  def self.authorize_transaction(transaction_id)
    response = put("/transactions/auth/#{transaction_id}",
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV.fetch('PROVIDER_API_KEY', 'test_key')}"
      },
      timeout: 10
    )

    raise ProviderError, "Provider auth failed: #{response.code}" unless response.success?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ProviderError, "Invalid JSON response: #{e.message}"
  rescue HTTParty::Error, Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
    raise ProviderError, "HTTP request failed: #{e.message}"
  end
end
