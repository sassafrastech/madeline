# frozen_string_literal: true

namespace :tww do
  task :migrate_new => :environment do
    I18n.locale = :es
    DIV_IDS = [2, 4, 13]
    OUTSIDE_MEMBER_IDS = [2, 62, 91, 133]

    @last_successful = begin
      File.read("tmp/migration_dumps/last_successful.txt").strip
    rescue Errno::ENOENT
      nil
    end

    txn_and_dump("destroy") do
      Organization.where(division_id: DIV_IDS).destroy_all
      Loan.where(division_id: DIV_IDS).destroy_all
    end

    orgs = Legacy::Cooperative.where(country: 'Argentina')
    txn_and_dump("orgs") do
      orgs.migrate_all
    end
    org_ids = orgs.pluck(:id)

    txn_and_dump("people") do
      Legacy::Member.where(country: 'Argentina')
        .or(Legacy::Member.where(id: OUTSIDE_MEMBER_IDS)).migrate_all
    end

    loans = Legacy::Loan.where(source_division: DIV_IDS)
    txn_and_dump("loans") do
      loans.migrate_all
    end
    loan_ids = loans.pluck(:id)

    events = Legacy::ProjectEvent.where(project_id: loan_ids)
    txn_and_dump("steps") do
      events.migrate_all
    end
    event_ids = events.pluck(:id)

    logs = Legacy::ProjectLog.where(project_id: loan_ids)
    txn_and_dump("logs") do
      logs.migrate_all
    end
    log_ids = logs.pluck(:id)

    all_media = Legacy::Media
    media = all_media.where(context_table: "Cooperatives", context_id: org_ids)
    media = media.or(all_media.where(context_table: "Loans", context_id: loan_ids))
    media = media.or(all_media.where(context_table: "ProjectLogs", context_id: log_ids))
    txn_and_dump("media") do
      media.migrate_all
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
    `ANNOTATE_SKIP_ON_DB_MIGRATE=1 bundle exec rake db:migrate`
  end
end
