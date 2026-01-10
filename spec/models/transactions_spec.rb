# spec/models/transaction_spec.rb
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'EUR',
        status: 'pending'
      )
      expect(transaction).to be_valid
    end

    it 'is invalid without external_id' do
      transaction = Transaction.new(
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'EUR',
        status: 'pending'
      )
      expect(transaction).not_to be_valid
    end

    it 'is invalid with duplicate external_id' do
      Transaction.create!(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'EUR',
        status: 'pending'
      )

      duplicate = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_456',
        amount: 500,
        currency: 'USD',
        status: 'pending'
      )
      expect(duplicate).not_to be_valid
    end

    it 'is invalid without provider_transaction_id' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        amount: 1000,
        currency: 'EUR',
        status: 'pending'
      )
      expect(transaction).not_to be_valid
    end

    it 'is invalid without amount' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        currency: 'EUR',
        status: 'pending'
      )
      expect(transaction).not_to be_valid
    end

    it 'is invalid with zero or negative amount' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 0,
        currency: 'EUR',
        status: 'pending'
      )
      expect(transaction).not_to be_valid

      transaction.amount = -100
      expect(transaction).not_to be_valid
    end

    it 'is invalid without currency' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        status: 'pending'
      )
      expect(transaction).not_to be_valid
    end

    it 'is invalid with incorrectly formatted currency' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'Euro',
        status: 'pending'
      )
      expect(transaction).not_to be_valid

      transaction.currency = 'eu'
      expect(transaction).not_to be_valid
    end

    it 'is invalid without status' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'EUR'
      )
      expect(transaction).not_to be_valid
    end

    it 'is invalid with incorrect status value' do
      transaction = Transaction.new(
        external_id: 'ext_123',
        provider_transaction_id: 'prov_123',
        amount: 1000,
        currency: 'EUR',
        status: 'invalid_status'
      )
      expect(transaction).not_to be_valid
    end
  end

  describe 'scopes' do
    before do
      Transaction.create!(
        external_id: 'ext_1',
        provider_transaction_id: 'prov_1',
        amount: 1000,
        currency: 'EUR',
        status: 'pending'
      )
      Transaction.create!(
        external_id: 'ext_2',
        provider_transaction_id: 'prov_2',
        amount: 2000,
        currency: 'USD',
        status: 'success'
      )
      Transaction.create!(
        external_id: 'ext_3',
        provider_transaction_id: 'prov_3',
        amount: 3000,
        currency: 'GBP',
        status: 'failed'
      )
    end

    it 'returns pending transactions' do
      expect(Transaction.pending.count).to eq(1)
      expect(Transaction.pending.first.status).to eq('pending')
    end

    it 'returns completed transactions' do
      expect(Transaction.completed.count).to eq(2)
      statuses = Transaction.completed.pluck(:status)
      expect(statuses).to contain_exactly('success', 'failed')
    end
  end
end
