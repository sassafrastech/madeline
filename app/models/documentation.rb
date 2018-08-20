# == Schema Information
#
# Table name: documentations
#
#  calling_action     :string
#  calling_controller :string
#  created_at         :datetime         not null
#  html_identifier    :string
#  id                 :integer          not null, primary key
#  updated_at         :datetime         not null
#

class Documentation < ApplicationRecord
  include Translatable
  attr_translatable :summary_content, :page_content

  validates :html_identifier, uniqueness: true
end
