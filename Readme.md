# Intercom Webhook Reassign Away Mode
- This is [Intercom webhook](https://docs.intercom.io/integrations/webhooks) processing code to 
   - reassign conversations to a custom admin/inbox instead of Unassigned 
   - when [away mode reassignment is enabled](https://docs.intercom.com/responding-to-users-and-visitors/set-expectations/automatically-reassign-conversations-when-youre-away)
   - Reassignment is done via the [Intercom API](https://developers.intercom.io/reference)
- Currently when you enable away mode with reassignment it will reassign all conversations to "Unassigned"
- With this code you can reassign these conversations to a custom admin / team inbox


## Setup - Environment Variable Configuration
- lists all variables needed for this script to work
- `TOKEN`
   - Only need regular standard access token for reassignment but need extended one if want to read API ids
	- Apply for an access token  https://app.intercom.io/developers/_
	- Read more about access tokens https://developers.intercom.com/reference#personal-access-tokens-1 
- `assignee_admin_id`
	- the ID of the teammate or inbox to reassign conversations to 
	- retrieve IDs via Admin API https://developers.intercom.io/reference#admins
- `bot_admin_id`
	- the ID of the admin that performs the reassignment (must be an admin not a team)
- For development just rename `.env.sample` to `.env` and modify values appropriately

## Running this locally

```
gem install bundler # install bundler
bundle install      # install dependencies
ruby app.rb         # run the code
ngrok http 4567     # uses https://ngrok.com/ to give you a public URL to your local code to process the webhooks
```

- Create a new webhook in the [Intercom Developer Hub](https://app.intercom.io/developers/_) > Webhooks page
- Listen on the following notification: "Conversation Assigned to teammate" / `conversation.admin.assigned`
- In webhook URL specify the ngrok URL

