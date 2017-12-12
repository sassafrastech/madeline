class Repayment < ActiveRecord::Base
  belongs_to :loan, :foreign_key => 'LoanID'

  delegate :division, :division=, to: :loan

  def paid; self.date_paid ? true : false; end

  def status
    if self.paid
      :paid
    elsif self.date_due < Date.today
      :overdue
    else
      :due
    end
  end

  def status_date
    # this may or may not be available so setting a date default value

    if self.paid
      "#{I18n.t :paid} #{I18n.l(self.date_paid, format: :long, default: '')}"
    else
      "#{I18n.t :due} #{I18n.l(self.date_due, format: :long, default: '')}"
    end
  end

  def amount_formatted
    if self.date_paid
      amount = self.amount_paid
    else
      amount = self.amount_due
    end
    loan.ensure_currency.format_amount(amount)
  end
end
