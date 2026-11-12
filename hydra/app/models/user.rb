class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Replaces Hydra::User - user_key is the canonical identifier Bulkrax
  # (and Devise/Blacklight) use to find/compare users.
  def self.find_by_user_key(key)
    find_by(email: key)
  end

  def user_key
    email
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end