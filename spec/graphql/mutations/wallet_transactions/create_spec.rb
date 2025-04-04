# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::WalletTransactions::Create, type: :graphql do
  let(:required_permission) { "wallets:top_up" }
  let(:membership) { create(:membership) }
  let(:customer) { create(:customer, organization: membership.organization) }
  let(:subscription) { create(:subscription, customer:) }
  let(:wallet) { create(:wallet, customer:, balance: 10.0, credits_balance: 10.0) }

  let(:mutation) do
    <<-GQL
    mutation ($input: CreateCustomerWalletTransactionInput!) {
      createCustomerWalletTransaction(input: $input) {
        collection {
          id
          status
          invoiceRequiresSuccessfulPayment
          metadata {
            key
            value
          }
        }
      }
    }
    GQL
  end

  before do
    subscription
    wallet
  end

  it_behaves_like "requires current user"
  it_behaves_like "requires current organization"
  it_behaves_like "requires permission", "wallets:top_up"

  it "creates a wallet transaction" do
    result = execute_graphql(
      current_user: membership.user,
      current_organization: membership.organization,
      permissions: required_permission,
      query: mutation,
      variables: {
        input: {
          walletId: wallet.id,
          paidCredits: "5.00",
          grantedCredits: "5.00",
          invoiceRequiresSuccessfulPayment: true,
          metadata: [
            {
              key: "fixed",
              value: "0"
            },
            {
              key: "test 2",
              value: "mew meta"
            }
          ]
        }
      }
    )

    result_data = result["data"]["createCustomerWalletTransaction"]
    expect(result_data["collection"].map { |wt| wt["status"] })
      .to contain_exactly("pending", "settled")
    expect(result_data["collection"].map { |wt| wt["invoiceRequiresSuccessfulPayment"] }).to all be true
    expect(result_data["collection"]).to all(include(
      "metadata" => contain_exactly(
        {"key" => "fixed", "value" => "0"},
        {"key" => "test 2", "value" => "mew meta"}
      )
    ))
  end
end
