module Legacy
  class OrgSnapshotData < ActiveRecord::Base
    establish_connection :legacy

    def self.create_questions
      defaults = { question_set_id: 2 } # criteria
      criteria_root = ::LoanQuestionSet.find(2).questions.root
      parent = ::Question.create(defaults.merge data_type: 'group', label: "[Migrated from loan fields]", parent: criteria_root)
      defaults.merge! parent: parent, data_type: 'number'
      ::Question.create(defaults.merge internal_name: :cooperative_members, label: "Cooperative members")
      ::Question.create(defaults.merge internal_name: :poc_ownership_percent, label: "POC ownership %")
      ::Question.create(defaults.merge internal_name: :women_ownership_percent, label: "Women ownership %")
      ::Question.create(defaults.merge internal_name: :environmental_impact_score, label: "Environmental impact score")
    end

    def self.migrate_all
      puts "organization snapshot data: #{Loan.migratable.count}"
      create_questions
      Loan.migratable.each(&:migrate_snapshot_data)
    end

  end
end
