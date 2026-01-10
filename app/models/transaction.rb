# app/models/transaction.rb
class Transaction < ApplicationRecord
  # Validations
  validates :external_id, presence: true, uniqueness: true
  validates :provider_transaction_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :status, presence: true, inclusion: { in: %w[pending success failed error] }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: %w[success failed]) }
end
