# frozen_string_literal: true

FactoryBot.define do
  factory :credit do
    invoice
    applied_coupon

    amount_cents { 200 }
    amount_currency { "EUR" }
  end

  factory :credit_note_credit, class: "Credit" do
    invoice
    credit_note

    amount_cents { 200 }
    amount_currency { "EUR" }
  end

  factory :progressive_billing_invoice_credit, class: "Credit" do
    invoice
    progressive_billing_invoice factory: :invoice

    amount_cents { 200 }
    amount_currency { "EUR" }
  end
end
