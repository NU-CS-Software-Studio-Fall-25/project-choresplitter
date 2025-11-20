class ChoreGroup < ApplicationRecord
  belongs_to :admin, class_name: "User"

  has_many :members, dependent: :destroy
  has_many :users, through: :members

  has_many :task_groups, dependent: :destroy
  has_many :tasks, through: :task_groups

  has_many :bills, dependent: :destroy
  has_many :bill_shares, through: :bills

  has_many :invitations, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :code,
    presence: true,
    length: { is: 5 },
    format: { with: /\A[A-Z0-9]{5}\z/ },
    uniqueness: { case_sensitive: true }

  before_validation :ensure_code, on: :create

  def to_param
    code
  end

  private

  def ensure_code
    return if code.present?
    self.code = self.class.generate_code
  end

  def self.generate_code
    loop do
      c = SecureRandom.alphanumeric(5).upcase
      break c unless exists?(code: c)
    end
  end
end
