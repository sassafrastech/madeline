# == Schema Information
#
# Table name: tasks
#
#  activity_message_value    :string(65536)    not null
#  id                        :bigint(8)        not null, primary key
#  job_class                 :string(255)      not null
#  job_enqueued_for_retry_at :datetime
#  job_first_started_at      :datetime
#  job_last_failed_at        :datetime
#  job_succeeded_at          :datetime
#  job_type_value            :string(255)      not null
#  num_attempts              :integer          default(0), not null
#  provider_job_id           :string
#

require 'rails_helper'

describe Task, :type => :model do

  describe "#enqueue" do
    let(:task) { create(:task, job_class: RecalculateLoanHealthJob) }
    it "creates a job and stores initial information" do
      task.enqueue
      task.reload
      expect(task.provider_job_id).not_to be_nil
      expect(task.status).to eq :pending
    end
  end

  describe "#status" do

    context "not started" do
      let(:task) { create(:task, provider_job_id: 1 ) }
      it "should be pending" do
        expect(task.status).to eq :pending
      end
    end

    context "started but not completed, failed, or stalled" do
      let(:task) { create(:task, provider_job_id: 1, job_first_started_at: Time.current) }
      it "should be in_progress" do
        expect(task.status).to eq :in_progress
      end
    end

    context "has completed successfully" do
      let(:task) { create(:task, provider_job_id: 1, job_first_started_at: Time.current - 1.minute, job_succeeded_at: Time.current) }
      it "should be succeeded" do
        expect(task.status).to eq :succeeded
      end
    end

    context "has started, failed and not yet succeeded" do
      let(:task) { create(:task,
        provider_job_id: 1,
        job_first_started_at: Time.current - 1.minute,
        job_last_failed_at: Time.current - 1.second,
        job_enqueued_for_retry_at: Time.current
      ) }

      it "should be stalled" do
        expect(task.status).to eq :stalled
      end
    end
  end

  describe "life cycle updates" do
    let(:task) { create(:task, job_class: RecalculateLoanHealthJob) }
    before do
      task.enqueue
    end

    describe "#start" do
      it "sets start time on task only once; increments num_attempts each call" do
        task.start
        first_start_time = task.reload.job_first_started_at
        expect(first_start_time).not_to be_nil
        expect(task.reload.num_attempts).to eq 1

        task.start
        expect(task.reload.job_first_started_at).to eq first_start_time
        expect(task.reload.num_attempts).to eq 2
      end
    end

    describe "#end_successfully" do
      it "marks success" do
        expect(task.job_succeeded_at).to be_nil
        task.end_successfully
        expect(task.reload.job_succeeded_at).not_to be_nil
      end
    end

    describe "#record_failure" do
      it "records failure" do
        expect(task.job_last_failed_at).to be_nil
        task.record_failure
        expect(task.reload.job_last_failed_at).not_to be_nil
      end
    end
  end
end