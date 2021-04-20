# frozen_string_literal: true

namespace :tww do
  task :migrate_new => :environment do
    ActiveRecord::Base.transaction do
      I18n.locale = :es
      DIV_IDS = [2, 4, 13]
      OUTSIDE_MEMBER_IDS = [2, 62]

      Organization.where(division_id: DIV_IDS).destroy_all
      Loan.where(division_id: DIV_IDS).destroy_all

      Legacy::Cooperative.where(country: 'Argentina').migrate_all
      Legacy::Member.where(country: 'Argentina').or(Legacy::Member.where(id: OUTSIDE_MEMBER_IDS)).migrate_all
      Legacy::Loan.where(source_division: DIV_IDS).migrate_all
      loan_ids = Legacy::Loan.where(source_division: DIV_IDS).pluck(:id)
      Legacy::ProjectEvent.where(project_id: loan_ids).migrate_all

      puts "Skip Log:"
      Legacy::Migration.skip_log.each { |line| puts line.join(",") }
      puts "Unexpected Errors:"
      Legacy::Migration.unexpected_errors.each { |line| puts line }

      unless ENV["DONT_ROLLBACK"]
        puts "Rolling back"
        raise ActiveRecord::Rollback, "Completed successfully"
      end
    end
  end
end
