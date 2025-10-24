json.extract! bill_share, :id, :bill_id, :member_id, :amount, :status, :created_at, :updated_at
json.url bill_share_url(bill_share, format: :json)
