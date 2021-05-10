# frozen_string_literal: true

namespace :tww do
  task :migrate_new => :environment do
    Rake::Task['db:migrate'].invoke

    I18n.locale = :es
    DIV_IDS = [2, 4, 13]
    OUTSIDE_MEMBER_IDS = [2, 62, 91, 133]
    loan_ids = nil
    event_ids = nil

    @last_successful = begin
      File.read("tmp/migration_dumps/last_successful.txt").strip
    rescue Errno::ENOENT
      nil
    end

    txn_and_dump("destroy") do
      Organization.where(division_id: DIV_IDS).destroy_all
      Loan.where(division_id: DIV_IDS).destroy_all
    end

    txn_and_dump("orgs") do
      Legacy::Cooperative.where(country: 'Argentina').migrate_all
    end

    txn_and_dump("people") do
      Legacy::Member.where(country: 'Argentina')
        .or(Legacy::Member.where(id: OUTSIDE_MEMBER_IDS)).migrate_all
    end

    txn_and_dump("loans") do
      loans = Legacy::Loan.where(source_division: DIV_IDS)
      loans.migrate_all
      loan_ids = loans.pluck(:id)
    end

    txn_and_dump("steps") do
      events = Legacy::ProjectEvent.where(project_id: loan_ids)
      events.migrate_all
      event_ids = events.pluck(:id)
    end

    txn_and_dump("logs") do
      logs = Legacy::ProjectLog.where(project_id: loan_ids)
      logs.migrate_all
    end
  end

  def txn_and_dump(name)
    if @last_successful.present?
      if name == @last_successful
        import_dump(name)
        @last_successful = nil
      else
        puts "Skipping #{name}"
      end
      return
    end
    ActiveRecord::Base.transaction do
      yield
    end
    puts "Dumping post #{name}"
    `pg_dump madeline_migration > tmp/migration_dumps/post_#{name}.sql`
    File.open("tmp/migration_dumps/last_successful.txt", "w") { |f| f.write(name) }
    puts "Skip Log:"
    Legacy::Migration.skip_log.each { |line| puts line.join(",") }
    puts "Unexpected Errors:"
    Legacy::Migration.unexpected_errors.each { |line| puts line }
  end

  def import_dump(name)
    puts "Loading last successful dump '#{name}'..."
    puts "Terminating connections"
    `psql madeline_migration -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'madeline_migration';"`
    puts "Dropping DB"
    `dropdb madeline_migration`
    puts "Creating DB"
    `createdb madeline_migration`
    puts "Importing dump"
    `psql madeline_migration < tmp/migration_dumps/post_#{name}.sql`
    puts "Running Rails migrations"
    `bundle exec rake db:migrate`
  end
end
