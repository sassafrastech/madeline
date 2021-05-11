# -*- SkipSchemaAnnotations
module Legacy
  class Media < ApplicationRecord
    establish_connection :legacy
    include LegacyModel

    NULLIFY_MEMBER_IDS = [0, 121, 122, 123, 140, 186, 242, 243]

    LEGACY_MEDIA_BASE_PATH = ENV['LEGACY_MEDIA_BASE_PATH'] || '../legacymedia'
    TYPE_MAP = {
      "Cooperatives" => "Organization",
      "Loans" => "Project",
      "ProjectLogs" => "ProjectLog"
    }

    def self.existing_media_paths
      return @existing_media_paths if defined?(@existing_media_paths)
      server_path = "/var/www/internal.labase.org/linkedMedia"
      list = `ssh ubuntu@52.206.58.37 "ssh sassafras@72.32.43.226 \"find #{server_path}\""`
      @existing_media_paths = list.split("\n").map { |path| [path, true] }.to_h
    end

    def uploader_id
      if NULLIFY_MEMBER_IDS.include?(member_id)
        Migration.skip_log << ["Media", id, "Nullified uploader_id b/c member #{member_id} not found"]
        nil
      else
        if (person = Person.find_by(legacy_id: member_id))
          person.id
        else
          Migration.unexpected_errors << "Person not found for MemberId: #{member_id} on Media #{id}"
          nil
        end
      end
    end

    def media_attachable
      return @media_attachable if defined?(@media_attachable)
      @media_attachable =
        case context_table
        when "ProjectLogs" then ::ProjectLog.find_by(legacy_id: context_id)
        when "Loans" then ::Loan.find_by(id: context_id)
        when "Cooperatives" then ::Organization.find_by(id: context_id)
        else Migration.unexpected_errors << "Invalid table #{context_table} for Media #{id}"
        end
    end

    def migration_data
      data = {
        legacy_id: id,
        legacy_path: media_path,
        media_attachable_type: TYPE_MAP[context_table],
        media_attachable_id: media_attachable.id,
        uploader_id: uploader_id,
        sort_order: priority,
        item: Rails.root.join("tmp", "placeholder.txt").open,
        kind_value: "document" # to be set post-migration when files copied
      }

      copy_translations(data, from: :caption, to: :caption)
      copy_translations(data, from: :description, to: :description)

      data
    end

    def migrate
      unless self.class.existing_media_paths["/var/www/internal.labase.org/#{media_path}"]
        Migration.skip_log << ["Media", id, "Not migrating b/c file '#{media_path}' doesn't exist"]
        return
      end
      if media_attachable.nil?
        Migration.skip_log << ["Media", id,
                               "#{TYPE_MAP[context_table]} with legacy ID #{context_id} not found"]
        return
      end
      data = migration_data
      pp data
      ::Media.create!(data)
    end
  end
end
