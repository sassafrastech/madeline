# == Schema Information
#
# Table name: loan_questions
#
#  created_at            :datetime         not null
#  data_type             :string
#  division_id           :integer          not null
#  has_embeddable_media  :boolean          default(FALSE), not null
#  id                    :integer          not null, primary key
#  internal_name         :string
#  loan_question_set_id  :integer
#  migration_position    :integer
#  number                :integer
#  override_associations :boolean          default(FALSE), not null
#  parent_id             :integer
#  position              :integer
#  required              :boolean          default(FALSE), not null
#  status                :string           default("active"), not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_loan_questions_on_loan_question_set_id  (loan_question_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (loan_question_set_id => loan_question_sets.id)
#

class LoanQuestionSerializer < ActiveModel::Serializer
  attributes :id, :name, :children, :parent_id, :fieldset, :optional, :required_loan_types, :status,
    :can_edit

  def initialize(*args, user: nil, **options)
    @user = user
    super(*args, options)
  end

  def name
    object.full_number_and_label
  end

  # jqtree expects children in a `children` key
  def children
    if object.children.present?
      # Recursively apply this serializer to children
      object.children.map { |node| self.class.new(node, user: @user) }
    end
  end

  def fieldset
    object.loan_question_set.internal_name.sub('loan_', '')
  end

  def optional
    !object.required?
  end

  def required_loan_types
    object.loan_question_requirements.map { |i| i.loan_type.label.to_s }
  end

  def status
    object.status.presence || "active"
  end

  def can_edit
    if @user
      Pundit.policy!(@user, object).edit?
    else
      return false
    end
  end
end
