# frozen_string_literal: true

class AddSlugToCustomers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :customers, bulk: true do |t|
        t.string :slug
        t.bigint :sequential_id
      end
    end

    LagoApi::Application.load_tasks
    Rake::Task["customers:generate_slug"].invoke
  end
end
