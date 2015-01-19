module GetResponse

  # Proxy class for contact related operations.
  class ContactProxy

    include Conditions

    def initialize(connection)
      @connection = connection
    end


    # Get all contacts from account. Conditions could be passed to method. Returned contacts
    # will be limited to passed conditions eg. to certain campaign. For more examples of conditions
    # visit: http://dev.getresponse.com/api-doc/#get_contacts
    # Example:
    #   @contact_proxy.all(:campaigns => ["my_campaign_id"])
    #
    # returns:: Array of GetResponse::Contact
    def all(conditions = {})
      response = @connection.send_request("get_contacts", conditions)
      build_contacts(response["result"])
    end

    # Get contact by email
    # optional limit query to given campaign_id
    #
    # returns:: instance of Getresponse::Contact
    # raises GRNotFound if empty result returned
    #
    def by_email(email_address, campaign_id=nil)
      response = @connection.send_request('get_contacts', 
                                          build_email_campaign_options(email_address, campaign_id)
                                         )
      if response['result'].empty?
        raise GRNotFound.new("Contact not found: #{email_address}")
      else
        attrs = response['result'].values.first.merge('id' => response['result'].keys.pop)
        Contact.new(attrs, @connection)
      end
    end

    # Get contact by ID
    # optional limit query to given campaign_id
    #
    # returns:: instance of Getresponse::Contact
    # raises GRNotFound if empty result returned
    #
    def by_id(id)
      response = @connection.send_request('get_contact', {'contact' => id })

      if response['result'].empty?
        raise GRNotFound.new("Contact not found: #{id}")
      else
        attrs = response['result'].values.first
        Contact.new(attrs, @connection)
      end
    end

    # Create new contact. Method can raise <tt>GetResponseError</tt>.
    #
    # returns:: GetResponse::Contact
    def create(attrs)
      contact = GetResponse::Contact.new(attrs, @connection)
      contact.save
      contact
    end


    # Get contacts subscription stats aggregated by date, campaign and contact’s origin.
    # Example:
    #
    #   # get stats for any camapign, any time period
    #   @contact_proxy.statistics
    #
    #   # get stats for selected camapigns, any time period
    #   @contact_proxy.statistics(:campaigns => ["cmp1", "cmp2"])
    #
    #   # get stats for specified date
    #   @contact_proxy.statistics(:created_on => {:at => Date.today})
    #   @contact_proxy.statistics(:created_on => {:from => "2011-01-01", :to => "2011-12-30"})
    #
    # @param conditions [Hash] conditions for statistics query, empty by default
    # @return [Hash] collection of aggregated statistics
    def statistics(conditions = {})
      conditions = parse_conditions(conditions)

      @connection.send_request("get_contacts_subscription_stats", conditions)["result"]
    end


    # Get deleted contacts.
    # Example:
    #
    #   # get all deleted contacts
    #   @contact_proxy.deleted
    #
    #   # get contacts deleted through api
    #   @contact_proxy.deleted(:reason => "api")
    #
    #   # get deleted contacts from campaign
    #   @contact_proxy.deleted(:campaigns => ["campaign_id"])
    #
    # @param conditions [Hash]
    # @return [Array]
    def deleted(conditions = {})
      conditions = parse_conditions(conditions)
      response = @connection.send_request("get_contacts_deleted", conditions)
      build_contacts(response["result"])
    end

    private

    def build_email_campaign_options(email, campaign_id=nil)
      email_hash = { 'email' => { 'EQUALS' => email} }
      ret = if campaign_id
              { 'campaigns' => [campaign_id] }.merge(email_hash) 
            else
              email_hash
            end
      return ret
    end
    
    # Build collection of <tt>Contact</tt> objects from service response.
    #
    # @param raw_contacts [Array] of Hashes parsed from GetResponse API response
    # @return [Array]
    def build_contacts(raw_contacts)
      raw_contacts.map do |raw_contact|
        Contact.new(raw_contact[1].merge("id" => raw_contact[0]), @connection)
      end
    end

  end

end
