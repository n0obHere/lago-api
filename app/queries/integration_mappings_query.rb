# frozen_string_literal: true

class IntegrationMappingsQuery < BaseQuery
  Result = BaseResult[:integration_mappings]
  Filters = BaseFilters[:integration_id, :mappable_type]

  def call
    integration_mappings = paginate(base_scope)
    integration_mappings = apply_consistent_ordering(integration_mappings)

    integration_mappings = with_integration_id(integration_mappings) if filters.integration_id
    integration_mappings = with_mappable_type(integration_mappings) if filters.mappable_type

    result.integration_mappings = integration_mappings
    result
  end

  private

  def base_scope
    ::IntegrationMappings::NetsuiteMapping.joins(:integration).where(integration: {organization:})
  end

  def with_integration_id(scope)
    scope.where(integration_id: filters.integration_id)
  end

  def with_mappable_type(scope)
    scope.where(mappable_type: filters.mappable_type)
  end
end
