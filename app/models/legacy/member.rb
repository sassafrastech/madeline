# -*- SkipSchemaAnnotations
module Legacy
  class Member < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    belongs_to :cooperative, foreign_key: 'CooperativeID'

    DONT_UPDATE_MADELINE_IDS = [1577]

    def self.migrate_all
      puts "---------------------------------------------------------"
      puts "Members: #{ self.count }"
      all.find_each(&:migrate)
    end

    def self.id_map
      @id_map ||= {}
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
          puts "Skipping update to person ##{person.id} except for legacy_id"
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
