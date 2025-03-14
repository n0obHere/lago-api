# frozen_string_literal: true

module WalletTransactions
  class CreateService < BaseService
    Result = BaseResult[:current_wallet, :wallet_transactions]

    def initialize(organization:, params:)
      @organization = organization
      @params = params

      super
    end

    def call
      # Normalize metadata
      params[:metadata] = [] if params[:metadata] == {}
      return result unless valid? # NOTE: validator sets result.current_wallet

      wallet_transactions = []
      @source = params[:source] || :manual
      @metadata = params[:metadata] || []
      invoice_requires_successful_payment = if params.key?(:invoice_requires_successful_payment)
        ActiveModel::Type::Boolean.new.cast(params[:invoice_requires_successful_payment])
      else
        result.current_wallet.invoice_requires_successful_payment
      end

      if params[:paid_credits]
        transaction = handle_paid_credits(
          wallet: result.current_wallet,
          credits_amount: BigDecimal(params[:paid_credits]).floor(5),
          invoice_requires_successful_payment:
        )
        wallet_transactions << transaction
      end

      if params[:granted_credits]
        transaction = handle_granted_credits(
          wallet: result.current_wallet,
          credits_amount: BigDecimal(params[:granted_credits]).floor(5),
          reset_consumed_credits: ActiveModel::Type::Boolean.new.cast(params[:reset_consumed_credits]),
          invoice_requires_successful_payment:
        )
        wallet_transactions << transaction
      end

      if params[:voided_credits]
        void_result = WalletTransactions::VoidService.call(
          wallet: result.current_wallet,
          credits_amount: BigDecimal(params[:voided_credits]).floor(5),
          from_source: source, metadata:
        )
        wallet_transactions << void_result.wallet_transaction
      end

      transactions = wallet_transactions.compact

      transactions.each { |wt| SendWebhookJob.perform_later("wallet_transaction.created", wt.reload) }

      result.wallet_transactions = transactions
      result
    end

    private

    attr_reader :organization, :params, :source, :metadata

    def handle_paid_credits(wallet:, credits_amount:, invoice_requires_successful_payment:)
      return if credits_amount.zero?

      wallet_transaction = WalletTransaction.create!(
        wallet:,
        transaction_type: :inbound,
        amount: wallet.rate_amount * credits_amount,
        credit_amount: credits_amount,
        status: :pending,
        source:,
        transaction_status: :purchased,
        invoice_requires_successful_payment:,
        metadata:
      )

      BillPaidCreditJob.perform_later(wallet_transaction, Time.current.to_i)

      wallet_transaction
    end

    def handle_granted_credits(wallet:, credits_amount:, invoice_requires_successful_payment:, reset_consumed_credits: false)
      return if credits_amount.zero?

      ActiveRecord::Base.transaction do
        wallet_transaction = WalletTransaction.create!(
          wallet:,
          transaction_type: :inbound,
          amount: wallet.rate_amount * credits_amount,
          credit_amount: credits_amount,
          status: :settled,
          settled_at: Time.current,
          source:,
          transaction_status: :granted,
          invoice_requires_successful_payment:,
          metadata:
        )

        Wallets::Balance::IncreaseService.new(
          wallet:,
          credits_amount:,
          reset_consumed_credits:
        ).call

        wallet_transaction
      end
    end

    def valid?
      WalletTransactions::ValidateService.new(
        result,
        **params.merge(organization: organization)
      ).valid?
    end
  end
end
