# frozen_string_literal: true

class AddUnaccentExtension < ActiveRecord::Migration[7.0]
  def up
    safety_assured { execute "CREATE EXTENSION IF NOT EXISTS unaccent" }
  end
end
