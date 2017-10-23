#############################################
# Environment Variable Configuration
# - lists all variables needed for this script to work
#############################################
# TOKEN
#     Only need regular standard access token for reassignment but need extended one if want to read API ids
#     Apply for an access token  https://app.intercom.io/developers/_
#     Read more about access tokens https://developers.intercom.com/reference#personal-access-tokens-1 
# assignee_admin_id
#     the ID of the teammate or inbox to reassign conversations to 
#     retrieve IDs via Admin API https://developers.intercom.io/reference#admins
# bot_admin_id 
#     the ID of the admin that performs the reassignment (must be an admin not a team)
#############################################
# For development just rename .env.sample to .env and modify values appropriately
#############################################
require 'sinatra'
require 'json'
require 'active_support/time'
require 'intercom'
require 'nokogiri'
require 'dotenv'
Dotenv.load

DEBUG = ENV["DEBUG"] || nil

post '/' do
  request.body.rewind
  payload_body = request.body.read
  if DEBUG then
    puts "==============================================================="
    puts payload_body
    puts "==============================================================="
  end
  verify_signature(payload_body)
  response = JSON.parse(payload_body)
  if DEBUG then
    puts "Topic Recieved: #{response['topic']}"
  end
  if is_supported_topic(response['topic']) then
    process_webhook(response)
  end
end

def init_intercom
  if @intercom.nil? then
    token = ENV["TOKEN"]
    @intercom = Intercom::Client.new(token: token)
  end
end

def is_supported_topic(topic)
  topic.index("conversation.admin.assigned")
end
def is_conversation_reassigned_from_away_mode(conversation_part)
  return conversation_part["part_type"].match(/away\_mode\_assignment/i)
end

def process_webhook(response)
  if DEBUG then
    puts "Process webhook....."
  end

  begin
    conversation_id = response["data"]["item"]["id"]
    if is_conversation_reassigned_from_away_mode(response["data"]["item"]["conversation_parts"]["conversation_parts"][0]) then
      puts "Found conversation #{conversation_id} assigned to Unassigned from away mode. Reassigning to custom admin/team!"
      reassign_conversation(conversation_id)
    end
  rescue Exception => e 
    if DEBUG then
      puts "Exception!"
      puts e.message
      puts e.backtrace.inspect  
    else
      puts "Exception =("
    end
    return
  end
end

def reassign_conversation(conversation_id)
  init_intercom
  admin_id = ENV["bot_admin_id"] 
  assignee_id = ENV["assignee_admin_id"] 
  puts "#{conversation_id}: #{admin_id} reassigning this converation to #{assignee_id}"
  @intercom.conversations.assign(id: conversation_id, assignee_id: assignee_id, admin_id: admin_id)
end

def verify_signature(payload_body)
  secret = ENV["secret"]
  expected = request.env['HTTP_X_HUB_SIGNATURE']

  if secret.nil? || secret.empty? then
    puts "No secret specified so accept all data"
  elsif expected.nil? || expected.empty? then
    puts "Not signed. Not calculating"
  else

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
    puts "Expected  : #{expected}"
    puts "Calculated: #{signature}"
    if Rack::Utils.secure_compare(signature, expected) then
      puts "   Match"
    else
      puts "   MISMATCH!!!!!!!"
      return halt 500, "Signatures didn't match!"
    end
  end
end