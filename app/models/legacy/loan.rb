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
      primary_id = Person.find_by(legacy_id: nil_if_zero(point_person))&.id
      secondary_id = Person.find_by(legacy_id: nil_if_zero(second))&.id
      secondary_id = nil if primary_id == secondary_id

      data = {
        id: id,
        division_id: source_division,
        organization_id: nil_if_zero(cooperative_id),
        name: name,
        primary_agent_id: primary_id,
        secondary_agent_id: secondary_id,
        status_value: status_option_value,
        loan_type_value: loan_type_option_value,
        public_level_value: public_level_option_value,
        currency_id: AGENTINIAN_PESO_ID,
        amount: amount,
        rate: rate,
        length_months: length,
        representative_id: Person.find_by(legacy_id: nil_if_zero(representative_id))&.id,
        signing_date: signing_date,
        projected_first_interest_payment_date: first_interest_payment,
        projected_first_payment_date: first_payment_date,
        projected_end_date: fecha_de_finalizacion,
        projected_return: projected_return
      }

      copy_translations(data, from: :short_description, to: :summary,
                              local_source: {en: "ShortDescriptionEnglish", es: "ShortDescription"})
      copy_translations(data, from: :description, to: :details,
                              local_source: {en: "DescriptionEnglish", es: "Description"})

      data
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
        Migration.skip_log << ["Loan", data[:id], "No coop"]
        return
      end
      if LOANS_WITH_NO_LOAN_TYPE.include?(data[:id])
        Migration.skip_log << ["Loan", data[:id], "No loan type"]
        return
      end
      pp data
      if ::Loan.find_by(id: data[:id])
        Migration.unexpected_errors << "Loan #{data[:id]} exists!"
      else
        begin
          ::Loan.create!(data)
        rescue StandardError => e
          Migration.unexpected_errors << e.to_s
        end
      end
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
        Migration.unexpected_errors << "No matching status_value found for #{nivel}"
      end
      value
    end

    def loan_type_option_value
      value =
        if loan_type.to_s == "0"
          ::Loan.loan_type_option_set.value_for_migration_id(1)
          Migration.skip_log << ["Loan", id, "Loan type was '0', set to 'Liquidity LoC' as a default"]
        else
          ::Loan.loan_type_option_set.value_for_migration_id(loan_type)
        end
      if value.nil?
        Migration.unexpected_errors << "No matching loan_type_value found for #{loan_type}"
      end
      value
    end

    def public_level_option_value
      # Default to Hidden if no value given in old DB
      value = PUBLIC_LEVEL_OPTIONS.value_for(nivel_publico) || "hidden"
      if value.nil?
        Migration.unexpected_errors << "No matching public_level_value found for #{nivel_publico}"
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
