# spec/factories/users.rb
FactoryBot.define do
    factory :user do
      sequence(:email) { |n| "user#{n}@example.com" }
      password { 'password123' }
      password_confirmation { 'password123' }
  
      trait :with_bookmarks do
        after(:create) do |user|
          create_list(:bookmark, 3, user: user)
        end
      end
    end
end