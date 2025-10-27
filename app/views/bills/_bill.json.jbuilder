json.extract! bill, :id, :chore_group_id, :member_id, :total_amount, :description, :created_at, :updated_at
json.url bill_url(bill, format: :json)
