# frozen_string_literal: true

namespace :tww do
  task :migrate_new => :environment do
    ActiveRecord::Base.transaction do
      I18n.locale = :es
      DIV_IDS = [2, 4, 13]

      Organization.where(division_id: DIV_IDS).destroy_all
      Loan.where(division_id: DIV_IDS).destroy_all

      Legacy::Cooperative.where(country: 'Argentina').migrate_all
      Legacy::Member.where(country: 'Argentina').migrate_all
      Legacy::Loan.where(source_division: DIV_IDS).migrate_all

      unless ENV["DONT_ROLLBACK"]
        puts "Rolling back"
        raise ActiveRecord::Rollback, "Completed successfully"
      end
    end
  end
end
