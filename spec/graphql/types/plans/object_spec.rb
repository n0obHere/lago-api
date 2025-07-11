# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::Plans::Object do
  subject { described_class }

  it do
    expect(subject).to have_field(:id).of_type("ID!")
    expect(subject).to have_field(:organization).of_type("Organization")
    expect(subject).to have_field(:amount_cents).of_type("BigInt!")
    expect(subject).to have_field(:amount_currency).of_type("CurrencyEnum!")
    expect(subject).to have_field(:bill_charges_monthly).of_type("Boolean")
    expect(subject).to have_field(:code).of_type("String!")
    expect(subject).to have_field(:description).of_type("String")
    expect(subject).to have_field(:has_overridden_plans).of_type("Boolean")
    expect(subject).to have_field(:interval).of_type("PlanInterval!")
    expect(subject).to have_field(:invoice_display_name).of_type("String")
    expect(subject).to have_field(:minimum_commitment).of_type("Commitment")
    expect(subject).to have_field(:name).of_type("String!")
    expect(subject).to have_field(:parent).of_type("Plan")
    expect(subject).to have_field(:pay_in_advance).of_type("Boolean!")
    expect(subject).to have_field(:trial_period).of_type("Float")
    expect(subject).to have_field(:activity_logs).of_type("[ActivityLog!]")
    expect(subject).to have_field(:charges).of_type("[Charge!]")
    expect(subject).to have_field(:taxes).of_type("[Tax!]")
    expect(subject).to have_field(:created_at).of_type("ISO8601DateTime!")
    expect(subject).to have_field(:updated_at).of_type("ISO8601DateTime!")
    expect(subject).to have_field(:deleted_at).of_type("ISO8601DateTime")
    expect(subject).to have_field(:usage_thresholds).of_type("[UsageThreshold!]")

    expect(subject).to have_field(:has_active_subscriptions).of_type("Boolean!")
    expect(subject).to have_field(:has_charges).of_type("Boolean!")
    expect(subject).to have_field(:has_customers).of_type("Boolean!")
    expect(subject).to have_field(:has_draft_invoices).of_type("Boolean!")
    expect(subject).to have_field(:has_subscriptions).of_type("Boolean!")

    expect(subject).to have_field(:active_subscriptions_count).of_type("Int!")
    expect(subject).to have_field(:charges_count).of_type("Int!")
    expect(subject).to have_field(:customers_count).of_type("Int!")
    expect(subject).to have_field(:draft_invoices_count).of_type("Int!")
    expect(subject).to have_field(:subscriptions_count).of_type("Int!")
  end
end
