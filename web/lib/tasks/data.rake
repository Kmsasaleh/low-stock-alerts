# frozen_string_literal: true

namespace :data do
  desc "Delete sales and webhook records older than their retention period"
  task prune: :environment do
    DataRetentionJob.perform_now
  end
end
