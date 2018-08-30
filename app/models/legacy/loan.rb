# -*- SkipSchemaAnnotations
module Legacy

class Loan < ApplicationRecord
  establish_connection :legacy
  include LegacyModel

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
    data = {
        id: self.id,
        division_id: source_division,
        organization_id: nil_if_zero(cooperative_id),
        name: name,
        # handled directly via Translations table
        # summary: short_description.translated_content,
        # details: description.translated_content,
        primary_agent_id: nil_if_zero(point_person),
        secondary_agent_id: nil_if_zero(second),
        status_value: status_option_value,
        loan_type_value: loan_type_option_value,
        public_level_value: public_level_option_value,
        currency_id: currency.id,
        amount: amount,
        rate: rate,
        length_months: length,
        representative_id: nil_if_zero(representative_id),
        signing_date: signing_date,
        first_interest_payment_date: first_interest_payment,
        first_payment_date: first_payment_date,
        end_date: fecha_de_finalizacion,
        projected_return: projected_return,
    }
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
    # puts "#{data[:id]}: #{data[:name]}"
    loan = ::Loan.find_or_create_by(id: data[:id])
    loan.update!(data)
  rescue StandardError => e
    $stderr.puts "#{self.class.name}[#{id}] error migrating loan: #{e} - skipping"
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
    # if self.cooperative then I18n.t :project_with, name: self.cooperative.Name
    # else I18n.t :project_id, id: self.ID.to_s end
    if self.cooperative
      return I18n.t(:project_with, name: self.cooperative.Name)
    else
      return I18n.t(:project_id, id: self.ID)
    end
  end

  def self.migratable
    all
  end

  def self.migrate_all
    puts "loans: #{self.count}"
    migratable.each &:migrate
    ::Loan.recalibrate_sequence(gap: 1000)

    puts "loan translations: #{ Legacy::Translation.where('RemoteTable' => 'Loans').count }"
    Legacy::Translation.where('RemoteTable' => 'Loans').each &:migrate
  end

  def self.purge_migrated
    puts "::Loan.delete_all"
    ::Loan.delete_all
  end


  def status_option_value
    MIGRATION_STATUS_OPTIONS.value_for(nivel)
  end

  def loan_type_option_value
    ::Loan.loan_type_option_set.value_for_migration_id(loan_type)
  end

  def public_level_option_value
    PUBLIC_LEVEL_OPTIONS.value_for(nivel_publico)
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
