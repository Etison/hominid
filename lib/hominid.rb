require 'xmlrpc/client'

class Hominid
  
  # MailChimp API Documentation: http://www.mailchimp.com/api/1.1/
  
  def initialize(autologin = true)
    load_monkey_brains
    login if autologin
    return self
  end
  
  def load_monkey_brains
    config = YAML.load(File.open("#{RAILS_ROOT}/config/hominid.yml"))[RAILS_ENV].symbolize_keys
    @chimpUsername  = config[:username].to_s
    @chimpPassword  = config[:password].to_s
    @send_goodbye   = config[:send_goodbye]
    @send_notify    = config[:send_notify]
    @double_opt     = config[:double_opt]
  end
  
  def login
    begin
      @chimpApi ||= XMLRPC::Client.new2("http://api.mailchimp.com/1.1/")
      @api_key = @chimpApi.call("login", @chimpUsername, @chimpPassword)
    rescue
      puts "***** Mail Chimp Error *****"
      puts "Connection: #{@chimpApi}"
      puts "Login: #{@chimpUsername}"
      puts "Password: #{@chimpPassword}"
    end
  end
  
  def add_api_key(key)
    begin
      @chimpApi ||= XMLRPC::Client.new2("http://api.mailchimp.com/1.1/")
      @chimpApi.call("apikeyAdd", @chimpUsername, @chimpPassword, key)
    rescue
      false
    end
  end
  
  def expire_api_key(key)
    begin
      @chimpApi ||= XMLRPC::Client.new2("http://api.mailchimp.com/1.1/")
      @chimpApi.call("apikeyExpire", @chimpUsername, @chimpPassword, key)
    rescue
      false
    end
  end
  
  def api_keys(include_expired = false)
    begin
      @chimpApi ||= XMLRPC::Client.new2("http://api.mailchimp.com/1.1/")
      @api_keys = @chimpApi.call("apikeys", @chimpUsername, @chimpPassword, @api_key, include_expired)
    rescue
      return nil
    end
  end
  
  ## Campaign related methods
  
  def campaign_content(campaign_id)
    # Get the content of a campaign
    begin
      @content = @chimpApi.call("campaignContent", @api_key, campaign_id)
    rescue
      return nil
    end
  end
  
  def campaigns(list_id = nil)
    # Get the campaigns for this account (optionally for a specific list)
    begin
      if list_id
        @campaigns = @chimpApi.call("campaigns", @api_key, list_id)
      else
        @campaigns = @chimpApi.call("campaigns", @api_key)
      end
    rescue
      return nil
    end
  end
  
  def create_campaign(type = 'regular', options = {}, content = {}, segment_options = {}, type_opts = {})
    # Create a new campaign
    begin
      @campaign = @chimpApi.call("campaignCreate", @api_key, type, options, content, segment_options, type_opts)
    rescue
      return nil
    end
  end
  
  def delete_campaign(campaign_id)
    # Delete a campaign
    begin
      @campaign = @chimpApi.call("campaignDelete", @api_key, campaign_id)
    rescue
      false
    end
  end
  
  def replicate_campaign(campaign_id)
    # Replicate a campaign (returns ID of new campaign)
    begin
      @campaign = @chimpApi.call("campaignReplicate", @api_key, campaign_id)
    rescue
      false
    end
  end
  
  def schedule_campaign(campaign_id, time = "#{1.day.from_now}")
    # Schedule a campaign
    ## TODO: Add support for A/B Split scheduling
    begin
      @chimpApi.call("campaignSchedule", @api_key, campaign_id, time)
    rescue
      false
    end
  end
  
  def send_now(campaign_id)
    # Send a campaign
    begin
      @chimpApi.call("campaignSendNow", @api_key, campaign_id)
    rescue
      false
    end
  end
  
  def send_test(campaign_id, emails = {})
    # Send a test of a campaign
    begin
      @chimpApi.call("campaignSendTest", @api_key, campaign_id, emails)
    rescue
      false
    end
  end
  
  def templates
    # Get the templates
    begin
      @templates = @chimpApi.call("campaignTemplates", @api_key)
    rescue
      return nil
    end
  end
  
  def update_campaign(campaign_id, name, value)
    # Update a campaign
    begin
      @chimpApi.call("campaignUpdate", @api_key, campaign_id, name, value)
    rescue
      false
    end
  end
  
  def unschedule_campaign(campaign_id)
    # Unschedule a campaign
    begin
      @chimpApi.call("campaignUnschedule", @api_key, campaign_id)
    rescue
      false
    end
  end
  
  ## Helper methods
  
  def html_to_text(content)
    # Convert HTML content to text
    begin
      @html_to_text = @chimpApi.call("generateText", @api_key, 'html', content)
    rescue
      return nil
    end
  end
  
  def convert_css_to_inline(html, strip_css = false)
    # Convert CSS styles to inline styles and (optionally) remove original styles
    begin
      @html_to_text = @chimpApi.call("inlineCss", @api_key, html, strip_css)
    rescue
      return nil
    end
  end
  
  ## List related methods
  
  def lists
    # Get all of the lists for this mailchimp account
    begin
      @lists = @chimpApi.call("lists", @api_key)
    rescue
      return nil
    end
  end
  
  def create_group(list_id, group)
    # Add an interest group to a list
    begin
      @chimpApi.call("listInterestGroupAdd", @api_key, group)
    rescue
      false
    end
  end
  
  def create_tag(list_id, tag, name, required = false)
    # Add a merge tag to a list
    begin
      @chimpApi.call("listMergeVarAdd", @api_key, tag, name, required)
    rescue
      false
    end
  end
  
  def delete_group(list_id, group)
    # Delete an interest group for a list
    begin
      @chimpApi.call("listInterestGroupDel", @api_key, group)
    rescue
      false
    end
  end
  
  def delete_tag(list_id, tag)
    # Delete a merge tag and all its members
    begin
      @chimpApi.call("listMergeVarDel", @api_key, tag)
    rescue
      false
    end
  end
  
  def groups(list_id)
    # Get the interest groups for a list
    begin
      @groups = @chimpApi.call("listInterestGroups", @api_key, list_id)
    rescue
      return nil
    end
  end
  
  def member(list_id, email)
    # Get a member of a list
    begin
      @member = @chimpApi.call("listMemberInfo", @api_key, list_id, email)
    rescue
      return nil
    end
  end
  
  def members(list_id, status = "subscribed")
    # Get members of a list based on status
    begin
      @members = @chimpApi.call("listMembers", @api_key, list_id, status)
    rescue
      return nil
    end
  end
  
  def merge_tags(list_id)
    # Get the merge tags for a list
    begin
      @merge_tags = @chimpApi.call("listMergeVars", @api_key, list_id)
    rescue
      return nil
    end
  end
  
  def subscribe(list_id, email, user_info = {}, email_type = "html")
    # Subscribe a member
    begin
      @chimpApi.call("listSubscribe", @api_key, list_id, email, user_info, email_type, @double_opt)
    rescue
      false
    end
  end
  
  def subscribe_many(list_id, subscribers)
    # Subscribe a batch of members
    # subscribers = {:EMAIL => 'example@email.com', :EMAIL_TYPE => 'html'} 
    begin
      @chimpApi.call("listBatchSubscribe", @api_key, list_id, subscribers, @double_opt, true)
    rescue
      false
    end
  end
  
  def unsubscribe(list_id, current_email)
    # Unsubscribe a list member
    begin
      @chimpApi.call("listUnsubscribe", @api_key, list_id, current_email, true, @send_goodbye, @send_notify)
    rescue
      false
    end
  end
  
  def unsubscribe_many(list_id, emails)
    # Unsubscribe an array of email addresses
    # emails = ['first@email.com', 'second@email.com'] 
    begin
      @chimpApi.call("listBatchUnsubscribe", @api_key, list_id, emails, true, @send_goodbye, @send_notify)
    rescue
      false
    end
  end
  
  def update_member(list_id, current_email, user_info = {}, email_type = "")
    # Update a member of this list
    begin
      @chimpApi.call("listUpdateMember", @api_key, list_id, current_email, user_info, email_type, true)
    rescue
      false
    end
  end

end