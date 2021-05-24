module Legacy

  class Migration

    def self.migrate_all
      OptionSet.find_by(model_attribute: :loan_type) || raise("Run rake db:seed first.")
      Legacy::Division.migrate_all
      Legacy::Cooperative.migrate_all
      Legacy::Member.migrate_all
      Legacy::LoanType.migrate_all
      Legacy::Loan.migrate_all
      Legacy::ProjectEvent.migrate_all
      Legacy::ProjectLog.migrate_all
      Legacy::Note.migrate_all
      Legacy::LoanQuestion.migrate_all
      Legacy::DueDiligencePerLoanType.migrate_all
      # Note, LoanResponseSet logic now pulls in LoanResponsesIFrame data
      Legacy::LoanResponseSet.migrate_all
      Legacy::OrgSnapshotData.migrate_all
    end

    # the core data which can be quickly migrated
    def self.migrate_core
      OptionSet.find_by(model_attribute: :loan_type) || raise("Run rake db:seed first.")
      Legacy::Division.migrate_all
      Legacy::Cooperative.migrate_all
      Legacy::Member.migrate_all
      Legacy::Loan.migrate_all
    end

    def self.migrate_media
      Legacy::Media.migrate_all
    end

    def self.migrate_secondary
      Legacy::ProjectEvent.migrate_all
      Legacy::ProjectLog.migrate_all
      Legacy::Note.migrate_all
      Legacy::LoanQuestion.migrate_all
      Legacy::DueDiligencePerLoanType.migrate_all
      # Note, LoanResponseSet logic now pulls in LoanResponsesIFrame data
      Legacy::LoanResponseSet.migrate_all
      Legacy::OrgSnapshotData.migrate_all
    end

    def self.migrate_questions
      Legacy::LoanQuestion.migrate_all
      Legacy::DueDiligencePerLoanType.migrate_all
      Legacy::LoanResponseSet.migrate_all
    end

    def self.purge_migrated
      Legacy::DueDiligencePerLoanType.purge_migrated
      Legacy::LoanQuestion.purge_migrated
      Legacy::Note.purge_migrated
      Legacy::ProjectLog.purge_migrated
      Legacy::ProjectEvent.purge_migrated
      Legacy::Loan.purge_migrated
      Legacy::Member.purge_migrated
      Legacy::Cooperative.purge_migrated
      Legacy::Division.purge_migrated
    end
  end
end
