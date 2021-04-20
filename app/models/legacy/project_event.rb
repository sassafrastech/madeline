# -*- SkipSchemaAnnotations
module Legacy
  # The Argentina data did not use groups or dependent dates.
  # So much of the earlier machinery for handling those complexities was deleted.
  class ProjectEvent < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    NULLIFY_MEMBER_IDS = [0, 247]

    def self.migratable
      # Don't migrate Finalized = -1 per Brendan 11/9/16
      where("Type = 'Paso' and Finalized > -1")
        .where(project_table: 'loans')
        .where(milestone_group: nil) # All Argentina steps have milestone_group NULL
    end

    # note, legacy data includes 11 references to a '0' member_id, and a bunch to 247 which doesn't exist
    def agent_id
      if NULLIFY_MEMBER_IDS.include?(member_id)
        nil
      else
        if Person.where(id: Member.id_map[member_id]).any?
          Member.id_map[member_id]
        else
          puts '**************************************************************************'
          puts "WARNING: Person not found for MemberId: #{member_id} on Step #{id}"
          puts '**************************************************************************'
          nil
        end
      end
    end

    def loan_id
      if ::Loan.where(id: project_id).exists?
        project_id
      else
        puts '**************************************************************************'
        puts "WARNING: Loan #{project_id} not found on Step #{id}"
        puts '**************************************************************************'
        nil
      end
    end

    # The Argentina data did not use groups or dependent dates.
    def migration_data
      {
        project_id: loan_id,
        agent_id: agent_id,
        is_finalized: (finalized == 1),
        step_type_value: MIGRATION_TYPE_OPTIONS.value_for(type),
        summary_es: summary,
        scheduled_start_date: date,
        actual_end_date: completed,
        scheduled_duration_days: duration == 0 ? 1 : duration,
        parent: find_or_create_parent_group
      }
    end

    def migrate
      data = migration_data
      pp data
      step = ::ProjectStep.create!(data)
      self.class.id_map[id] = step.id
    end

    def find_or_create_parent_group
      return nil if loan_id.nil?
      ProjectGroup.find_or_create_by!(project_id: project_id)
    end

    MIGRATION_TYPE_OPTIONS = TransientOptionSet.new(
        [ [:milestone, 'Paso'],
          [:agenda, 'Agenda'], # note, agenda items not currently scoped for migration
        ]
    )
  end
end
