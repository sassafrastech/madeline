# -*- SkipSchemaAnnotations
module Legacy
  class Member < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    belongs_to :cooperative, foreign_key: 'CooperativeID'

    DONT_UPDATE_MADELINE_IDS = [2, 1577]

    def self.migrate_all
      person = Person.create!(
        first_name: "Unknown",
        last_name: "2018 User",
        name: "Unknown 2018 User",
        legacy_id: 274,
        country_id: Country.find_by(name: "Argentina").id,
        division_id: 4
      )
      id_map[274] = person.id
      super
    end

    def division
      if username == 'brendan'
        ::Division.root
      elsif cooperative
        cooperative.division
      else
        Legacy::Division.from_country(country)
      end
    end

    def country
      self[:country]&.strip&.titleize
    end

    def migration_data
      {
        division_id: division.id,
        primary_organization_id: cooperative_id,
        first_name: first_name&.strip.presence,
        last_name: last_name&.strip.presence,
        name: "#{first_name&.strip} #{last_name&.strip}",
        primary_phone: phone&.strip.presence,
        street_address: address&.strip.presence,
        city: city&.strip.presence,
        country_id: Country.find_by(name: country&.strip.presence)&.id,
        tax_no: national_id&.strip.presence,
        birth_date: birth_date,
        legacy_id: id
      }
    end

    def migrate
      data = migration_data
      person = Person.find_by(first_name: first_name&.strip.presence, last_name: last_name&.strip.presence)
      if person
        if DONT_UPDATE_MADELINE_IDS.include?(person.id)
          Migration.skip_log << ["Person", person.id, "Skipping update b/c Madeline data seems newer"]
          person.update!(legacy_id: id)
        else
          person.assign_attributes(data.without(:division_id))
          puts "Updated person #{person.id}: #{person.changes}"
          person.save
        end
      else
        puts "Creating person"
        pp data
        person = Person.create!(data)
      end
      self.class.id_map[id] = person.id
    end
  end
end
