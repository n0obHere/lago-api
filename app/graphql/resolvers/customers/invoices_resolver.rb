# frozen_string_literal: true

module Resolvers
  module Customers
    class InvoicesResolver < Resolvers::BaseResolver
      include AuthenticableApiUser
      include RequiredOrganization

      REQUIRED_PERMISSION = "invoices:view"

      description "Query invoices of a customer"

      argument :customer_id, type: ID, required: true
      argument :limit, Integer, required: false
      argument :page, Integer, required: false
      argument :search_term, String, required: false
      argument :status, [Types::Invoices::StatusTypeEnum], required: false

      type Types::Invoices::Object.collection_type, null: false

      def resolve(customer_id: nil, status: nil, page: nil, limit: nil, search_term: nil)
        result = InvoicesQuery.call(
          organization: current_organization,
          pagination: {page:, limit:},
          search_term:,
          filters: {
            customer_id:,
            status:
          }
        )

        result.invoices
      rescue ActiveRecord::RecordNotFound
        not_found_error(resource: "customer")
      end
    end
  end
end
