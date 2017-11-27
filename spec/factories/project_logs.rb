# == Schema Information
#
# Table name: project_logs
#
#  agent_id              :integer
#  created_at            :datetime         not null
#  date                  :date
#  date_changed_to       :date
#  id                    :integer          not null, primary key
#  progress_metric_value :string
#  project_step_id       :integer
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_project_logs_on_agent_id         (agent_id)
#  index_project_logs_on_project_step_id  (project_step_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => people.id)
#  fk_rails_...  (project_step_id => timeline_entries.id)
#

FactoryBot.define do
  factory :project_log do
    project_step
    association :agent, factory: :person
    date { Faker::Date.between(Date.civil(2004, 01, 01), Date.today) }
    progress_metric_value { ["behind", "on_time", "ahead"].sample }
    transient_division

    # for now parent must be saved before assigning the translatable fields
    after(:create) do |log|
      log.set_summary(Faker::Lorem.sentences(3))
      log.set_details(Faker::Lorem.paragraphs(3))
      log.set_additional_notes(Faker::Lorem.sentences(3))
      log.set_private_notes(Faker::Lorem.paragraph)
    end

    trait :old do
      date { Faker::Date.between(60.days.ago, 30.days.ago) }
    end

    trait :recent do
      date { Faker::Date.between(5.days.ago, 1.day.ago) }
    end

  end
end
