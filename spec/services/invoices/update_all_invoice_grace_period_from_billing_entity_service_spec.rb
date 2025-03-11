# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoices::UpdateAllInvoiceGracePeriodFromBillingEntityService do
  subject { described_class.new(billing_entity:, old_grace_period:) }

  let(:billing_entity) { create(:billing_entity) }
  let(:organization) { billing_entity.organization }
  let(:old_grace_period) { 12 }

  context "without draft invoices" do
    it "enqueues zero jobs" do
      expect { subject.call }.not_to enqueue_job(Invoices::UpdateGracePeriodFromBillingEntityJob)
    end
  end

  context "with draft invoice present" do
    let(:draft_invoice) { create(:invoice, :draft, organization:) }

    before { draft_invoice }

    it "enqueues 1 job for the draft invoice" do
      expect { subject.call }.to enqueue_job(Invoices::UpdateGracePeriodFromBillingEntityJob)
        .with(draft_invoice, old_grace_period)
    end

    context "with finalized invoice present" do
      let(:finalized_invoice) { create(:invoice, :finalized, organization:) }

      before { finalized_invoice }

      it "enqueues only 1 job for the draft invoice" do
        expect { subject.call }.to enqueue_job(Invoices::UpdateGracePeriodFromBillingEntityJob)
          .with(draft_invoice, old_grace_period)
      end
    end
  end
end
