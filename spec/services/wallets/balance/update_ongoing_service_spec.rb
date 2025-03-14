# frozen_string_literal: true

require "rails_helper"

RSpec.describe Wallets::Balance::UpdateOngoingService, type: :service do
  subject(:update_service) { described_class.new(wallet:, total_usage_amount_cents:, pay_in_advance_usage_amount_cents:) }

  let(:organization) { create(:organization) }
  let(:customer) { create(:customer, organization:) }
  let(:wallet) do
    create(
      :wallet,
      customer:,
      balance_cents: 1000,
      ongoing_balance_cents: 800,
      ongoing_usage_balance_cents: 200,
      credits_balance: 10.0,
      credits_ongoing_balance: 8.0,
      credits_ongoing_usage_balance: 2.0,
      ready_to_be_refreshed: true
    )
  end
  let(:total_usage_amount_cents) { 450 }
  let(:pay_in_advance_usage_amount_cents) { 0 }

  before { wallet }

  describe "#call" do
    it "updates wallet balance" do
      create(:invoice, :draft, customer:, organization:, total_amount_cents: 150)

      expect { update_service.call }
        .to change(wallet.reload, :ongoing_usage_balance_cents).from(200).to(600)
        .and change(wallet, :credits_ongoing_usage_balance).from(2.0).to(6.0)
        .and change(wallet, :ongoing_balance_cents).from(800).to(400)
        .and change(wallet, :credits_ongoing_balance).from(8.0).to(4.0)
        .and change(wallet, :ready_to_be_refreshed).from(true).to(false)

      expect(wallet).not_to be_depleted_ongoing_balance
    end

    context "when usage amount is greater than the balance" do
      let(:total_usage_amount_cents) { 1500 }

      it "updates wallet ongoing balance to a negative value" do
        expect { update_service.call }
          .to change(wallet.reload, :ongoing_usage_balance_cents).from(200).to(1500)
          .and change(wallet, :credits_ongoing_usage_balance).from(2.0).to(15)
          .and change(wallet, :ongoing_balance_cents).from(800).to(-500)
          .and change(wallet, :credits_ongoing_balance).from(8.0).to(-5.0)
      end

      it "sets depleted_ongoing_balance to true" do
        expect { update_service.call }
          .to change(wallet.reload, :depleted_ongoing_balance).from(false).to(true)

        expect { update_service.call }
          .not_to change(wallet.reload, :depleted_ongoing_balance).from(true)
      end

      it "sends depleted_ongoing_balance webhook" do
        expect { update_service.call }
          .to have_enqueued_job(SendWebhookJob)
          .with("wallet.depleted_ongoing_balance", Wallet)
      end
    end
  end
end
