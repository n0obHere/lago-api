# frozen_string_literal: true

module CurrentContext
  thread_mattr_accessor :membership, :source, :email, :api_key_id
end
