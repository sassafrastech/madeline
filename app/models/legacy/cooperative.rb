# -*- SkipSchemaAnnotations
module Legacy
  class Cooperative < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    def division
      Legacy::Division.from_country(self.country)
    end

    def migration_data
      data = {
        id: self.id,
        division_id: division.id,
        name: name&.strip.presence,
        legal_name: nombre_legal_completo&.strip.presence,
        primary_phone: telephone&.strip.presence,
        email: email&.strip.presence,
        street_address: address&.strip.presence,
        city: city&.strip.presence,
        neighborhood: borough&.strip.presence,
        state: state&.strip.presence,
        country_id: Country.find_by(name: self.country)&.id,
        tax_no: tax_id&.strip.presence,
        website: self[:web],
        alias: self.alias&.strip.presence,
        sector: sector&.strip.presence,
        industry: industry&.strip.presence,
        referral_source: source&.strip.presence,
        is_recovered: (recuperada == 1),
        contact_notes: contact&.strip.presence
      }
      data
    end

    def migrate
      pp(migration_data)
      Organization.create!(migration_data)
    end
  end
end
