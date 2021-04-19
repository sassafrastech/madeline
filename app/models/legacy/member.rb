# -*- SkipSchemaAnnotations
module Legacy

class Member < ApplicationRecord
  establish_connection :legacy
  include LegacyModel

  belongs_to :cooperative, foreign_key: 'CooperativeID'

  def division
    if username == 'brendan'
      ::Division.root
    elsif cooperative
      cooperative.division
    else
      Legacy::Division.from_country(self.country)
    end
  end

  def migration_data
    data = {
        id: self.id,
        division_id: division.id,
        primary_organization_id: cooperative_id,
        first_name: first_name&.strip.presence,
        last_name: last_name&.strip.presence,
        name: "#{first_name} #{last_name}",
        primary_phone: phone,
        street_address: address&.strip.presence,
        city: city&.strip.presence,
        country_id: Country.find_by(name: self.country&.strip.presence).try(:id),
        tax_no: national_id,
    }
    if access_status > 0 && password.present? && username.present?
      email = "#{username.downcase}@theworkingworld.org"
      if Person.where(email: email).exists?
        $stderr.puts "skipping system access status for Person #{data[:id]} with non-unique email: #{email}"
      else
        data[:has_system_access] = true
        data[:email] = email
        adjusted_password = password.ljust(8, '0')
        data[:password] = data[:password_confirmation] = adjusted_password
        data[:access_role] = username == 'brendan' ? :admin : :member
      end
    end
    data
  end

  def migrate
    data = migration_data
    # puts "#{data[:id]}: #{data[:name]}"
    person = ::Person.find_or_create_by(id: data[:id])
    person.update!(data)
  end


  def self.migrate_all
    puts "members: #{ self.count }"
    self.all.each &:migrate
    ::Person.recalibrate_sequence(gap: 1000)
  end

  def self.purge_migrated
    puts "Person.destroy_all"
    ::Person.destroy_all
  end

end

end
