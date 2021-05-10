# -*- SkipSchemaAnnotations
module Legacy
  class ProjectLog < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    DEFAULT_STEP_NAME = '[Paso para contener nota emigratada]'
    NULLIFY_MEMBER_IDS = [0, 249, 280, 282]

    def self.migratable
      where("ProjectTable NOT IN ('BasicProjects', 'ProjectTemplates')")
    end

    def project
      Loan.find(project_id)
    end

    # note, legacy data includes 44 invalid references to a '0' member_id
    def agent_id
      return @agent_id if defined?(@agent_id)
      @agent_id =
        if NULLIFY_MEMBER_IDS.include?(member_id)
          Migration.skip_log << ["ProjectLog", id, "Nullified agent_id b/c member #{member_id} not found"]
          nil
        else
          if (person = Person.find_by(legacy_id: member_id))
            person.id
          else
            Migration.unexpected_errors << "Person not found for MemberId: #{member_id} on Log #{id}"
            nil
          end
        end
    end

    def date
      return @date if defined?(@date)
      return @date = self[:Date] unless self[:Date].nil?
      @date = Loan.find_by(id: project_id).signing_date
      Migration.skip_log << ["ProjectLog", id, "Date was NULL, set to Loan signing date of #{@date}"]
      @date
    end

    def migration_data
      # note the legacy db has many invalid references to either a 0 or 1 PasoID
      if paso_id && paso_id > 1 && (step = ProjectStep.find_by(legacy_id: paso_id))
        project_step_id = step.id
      else
        loan = ::Loan.find_by(id: project_id)
        if loan.nil?
          Migration.unexpected_errors <<
            "ProjectLog has no associated step and Loan #{project_id} doesn't exist"
          return nil
        end
        project_step_id = default_step(loan).id
      end

      data = {
        legacy_id: id,
        project_step_id: project_step_id,
        agent_id: agent_id,
        progress_metric_value:
          ::ProjectLog.progress_metric_option_set.value_for_migration_id(progress_metric),
        date: date
      }
      data[:summary] = explanation.strip if explanation&.strip.present?
      data[:details] = detailed_explanation.strip if detailed_explanation&.strip.present?
      data[:additional_notes] = additional_notes.strip if additional_notes&.strip.present?
      data[:private_notes] = notas_privadas.strip if notas_privadas&.strip.present?
      data
    end

    def migrate
      if project_table.downcase != 'loans'
        Migration.skip_log << ["ProjectLog", id, "Not migrating b/c ProjectTable = #{project_table}"]
        return
      end
      if project_id <= 0
        Migration.skip_log << ["ProjectLog", id, "Not migrating b/c ProjectID = #{project_table}"]
        return
      end
      data = migration_data
      if data
        pp(data)
        log = ::ProjectLog.create!(data)
      end
    end

    # creates / reuses a default step when migrating ProjectLogs without a proper owning step
    def default_step(loan)
      puts "Creating default step for Loan #{loan.id} to house Log #{id}"
      step = ProjectStep.create!(
        parent: ProjectGroup.find_or_create_by!(project_id: project_id),
        project: loan,
        scheduled_start_date: date,
        agent_id: agent_id,
        summary: DEFAULT_STEP_NAME,
        step_type_value: "milestone" # Old system didn't have 'checkin' type
      )
      pp(step)
      step
    end
  end
end
