json.products do
  json.array! @subscriptions do |subscription|
    json.partial! 'api/v1/subscriptions/subscription', subscription: subscription
  end
end
json.pagination do
  json.page @page
  json.page_length @page_length
  json.total_filtered_records @subscriptions.size
  json.total_records @unfiltered_size
end
