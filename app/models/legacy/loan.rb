# -*- SkipSchemaAnnotations
module Legacy
  class Loan < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    AGENTINIAN_PESO_ID = 1
    LOANS_WITH_NO_COOP = [262, 1517, 10273]
    LOANS_WITH_NO_LOAN_TYPE = [1515, 1517]

    belongs_to :cooperative, :foreign_key => 'CooperativeID'
    belongs_to :division, :foreign_key => 'SourceDivision'

    def currency
      @currency ||= division.ensure_country.default_currency
    end

    # beware, there are a lot of invalid '0' foreign key refs in the legacy data
    def nil_if_zero(val)
      val == 0 ? nil : val
    end

    def migration_data
      primary_id = Member.id_map[nil_if_zero(point_person)]
      secondary_id = Member.id_map[nil_if_zero(second)]
      secondary_id = nil if primary_id == secondary_id

      {
        id: id,
        division_id: source_division,
        organization_id: nil_if_zero(cooperative_id),
        name: name,
        summary_es: short_description&.strip.presence,
        details_es: description&.strip.presence,
        summary_en: short_description_english&.strip.presence,
        details_en: description_english&.strip.presence,
        primary_agent_id: primary_id,
        secondary_agent_id: secondary_id,
        status_value: status_option_value,
        loan_type_value: loan_type_option_value,
        public_level_value: public_level_option_value,
        currency_id: AGENTINIAN_PESO_ID,
        amount: amount,
        rate: rate,
        length_months: length,
        representative_id: Member.id_map[nil_if_zero(representative_id)],
        signing_date: signing_date,
        projected_first_interest_payment_date: first_interest_payment,
        projected_first_payment_date: first_payment_date,
        projected_end_date: fecha_de_finalizacion,
        projected_return: projected_return
      }
    end

    def org_snapshot_data
      data = {
        cooperative_members: cooperative_members,
        poc_ownership_percent: poc_ownership,
        women_ownership_percent: women_ownership,
        environmental_impact_score: environmental_impact
      }
      data
    end

    def migrate
      data = migration_data
      if LOANS_WITH_NO_COOP.include?(data[:id])
        puts "skpping loan #{data[:id]} b/c no coop"
        return
      end
      if LOANS_WITH_NO_LOAN_TYPE.include?(data[:id])
        puts "skpping loan #{data[:id]} b/c no loan type"
        return
      end
      pp data
      if ::Loan.find_by(id: data[:id])
        puts '**************************************************************************'
        puts "Loan #{data[:id]} exists!"
        puts '**************************************************************************'
      else
        begin
          ::Loan.create!(data)
        rescue StandardError => e
          puts '**************************************************************************'
          puts e
          puts '**************************************************************************'
        end
      end
    end

    def migrate_snapshot_data
      data = org_snapshot_data
      new_record = ::Loan.find(migration_data[:id])
      if data.values.any?(&:present?)
        new_record.create_criteria unless new_record.criteria
        data.each do |key, val|
          question = new_record.criteria.question(key)
          new_record.criteria.set_response(question, number: val)
        end
        new_record.criteria.save!
      end
    rescue StandardError => e
      $stderr.puts "#{self.class.name}[#{id}] error migrating organization snapshot data: #{e} - skipping"
    end

    def name
      if cooperative
        return I18n.t(:project_with, name: cooperative.Name.strip)
      else
        return I18n.t(:project_id, id: self.ID)
      end
    end

    def status_option_value
      value = MIGRATION_STATUS_OPTIONS.value_for(nivel)
      if value.nil?
        puts '**************************************************************************'
        puts "WARNING: No matching status_value found for #{nivel}"
        puts '**************************************************************************'
      end
      value
    end

    def loan_type_option_value
      value = ::Loan.loan_type_option_set.value_for_migration_id(loan_type)
      if value.nil?
        puts '**************************************************************************'
        puts "WARNING: No matching loan_type_value found for #{loan_type}"
        puts '**************************************************************************'
      end
      value
    end

    def public_level_option_value
      # Default to Hidden if no value given in old DB
      value = PUBLIC_LEVEL_OPTIONS.value_for(nivel_publico) || "Hidden"
      if value.nil?
        puts '**************************************************************************'
        puts "WARNING: No matching public_level_value found for #{nivel_publico}"
        puts '**************************************************************************'
      end
      value
    end

    MIGRATION_STATUS_OPTIONS = Legacy::TransientOptionSet.new(
        [ ['active', 'Prestamo Activo'],
          ['completed', 'Prestamo Completo'],
          ['frozen', 'Prestamo Congelado'],
          ['liquidated', 'Prestamo Liquidado'],
          ['prospective', 'Prestamo Prospectivo'],
          ['refinanced', 'Prestamo Refinanciado'],
          ['relationship', 'Relacion'],
          ['relationship_active', 'Relacion Activo']
        ])

    PUBLIC_LEVEL_OPTIONS = Legacy::TransientOptionSet.new(
        [ ['featured', 'Featured'],
          ['hidden', 'Hidden'],
        ])
  end
end
