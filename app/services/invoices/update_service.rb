# frozen_string_literal: true

module Invoices
  class UpdateService < BaseService
    def initialize(invoice:, params:, webhook_notification: false)
      @invoice = invoice
      @params = params
      @webhook_notification = webhook_notification

      super
    end

    def call
      return result.not_found_failure!(resource: "invoice") if invoice.nil?
      return result.not_allowed_failure!(code: "metadata_on_draft_invoice") if invoice.draft? && params[:metadata]

      if params.key?(:payment_status) && !valid_payment_status?(params[:payment_status])
        return result.single_validation_failure!(
          field: :payment_status,
          error_code: "value_is_invalid"
        )
      end

      unless valid_metadata_count?(metadata: params[:metadata])
        return result.single_validation_failure!(
          field: :metadata,
          error_code: "invalid_count"
        )
      end

      old_payment_status = invoice.payment_status
      invoice.payment_status = params[:payment_status] if params.key?(:payment_status)

      if invoice.draft? && (old_payment_status != invoice.payment_status)
        return result.not_allowed_failure!(code: "payment_status_update_on_draft_invoice")
      end

      if params.key?(:ready_for_payment_processing) && !invoice.voided?
        invoice.ready_for_payment_processing = params[:ready_for_payment_processing]
      end

      if params.key?(:total_paid_amount_cents) && params[:total_paid_amount_cents].present?
        invoice.total_paid_amount_cents = params[:total_paid_amount_cents]
      end

      ActiveRecord::Base.transaction do
        if invoice.payment_overdue? && invoice.payment_succeeded?
          invoice.payment_overdue = false

          if invoice.payment_requests.where.not(dunning_campaign_id: nil).exists?
            invoice.customer.reset_dunning_campaign!
          end
        end

        invoice.save!

        Invoices::Metadata::UpdateService.call(invoice:, params: params[:metadata]) if params[:metadata]
      end

      if params.key?(:payment_status)
        handle_prepaid_credits(params[:payment_status])
        Invoices::UpdateFeesPaymentStatusJob.perform_later(invoice)
        if old_payment_status != params[:payment_status] && invoice.visible?
          deliver_webhook
          Utils::ActivityLog.produce(invoice, "invoice.payment_status_updated")
        end
      end

      result.invoice = invoice
      Integrations::Aggregator::Invoices::Hubspot::UpdateJob.perform_later(invoice:) if invoice.should_update_hubspot_invoice?
      result
    rescue ActiveRecord::RecordInvalid => e
      result.record_validation_failure!(record: e.record)
    end

    private

    attr_reader :invoice, :params, :webhook_notification

    def valid_payment_status?(payment_status)
      Invoice::PAYMENT_STATUS.include?(payment_status&.to_sym)
    end

    def handle_prepaid_credits(payment_status)
      return unless invoice.invoice_type&.to_sym == :credit
      return unless %i[succeeded failed].include?(payment_status.to_sym)

      Invoices::PrepaidCreditJob.perform_later(invoice, payment_status.to_sym)
    end

    def valid_metadata_count?(metadata:)
      return true if metadata.blank?
      return true if metadata.count <= ::Metadata::InvoiceMetadata::COUNT_PER_INVOICE

      false
    end

    def deliver_webhook
      return unless webhook_notification

      SendWebhookJob.perform_later("invoice.payment_status_updated", invoice)
    end
  end
end
