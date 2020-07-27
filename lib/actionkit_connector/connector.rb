require 'httparty'

module ActionKitConnector
  class Connector
    include HTTParty
    headers({'Content-Type' => 'application/json', 'charset' => 'UTF-8'})

    attr_accessor :base_url

    def create_action(data)
      self.class.post('/action/', prep_options(data))
    end

    def create_donation_action(data)
      self.class.post('/donationpush/', prep_options(data))
    end

    # Iniatiates a batch upload of user information through and import page
    #
    # @param [String] import_page_id The id of the import page you wish to load data through. 
    # @param [File] file A Ruby file object (or equivalent IOstream) containing the CSV to upload
    # @param [Hash] other_params Other options you wish to pass to the upload
    # @param [Boolean] danger_check Should a safety check be performed to make sure the 
    #   page doesn't change the users language or subscriptions

    def batch_upsert_users(import_page_id, file, other_params, danger_check = true)
      page = import_page(import_page_id)
      if danger_check && page.slice('language', 'subscribe', 'unsubscribe', 'unsubscribe_all').values.any? 
        raise "Aborting because import page is set to change users' language or subscriptions. Re-run with danger_check = false if you are sure you want to do this."
      end

      params = {
        basic_auth: self.auth,
        body: {
          upload: file,
          page: page['title'],
        }.merge(other_params)
      }

      response = self.class.post('/upload/', params)
      raise BatchUpsertUsersError, response.body unless response.code == 201
      response.headers['location'].split('/').last.to_i # Get the ID of the upload
    end

    # Returns status information about an upload in progress
    #
    # @param [Int] id The ID of the upload.
    def get_upload(id)
      self.class.get("/upload/#{id}/", { basic_auth: self.auth })
    end

    # Initializes a connector to the ActionKit API.
    # A new connection is created on each call, so there
    # no need to worry about resource utilization.
    #
    # @param [String] username The username of your ActionKit user.
    # @param [String] password The password for your ActionKit user.
    # @param [String] base_url The base url of your ActionKit instance.
    def initialize(username, password, base_url)
      @username = username
      @password = password
      @base_url = base_url
      self.class.base_uri(base_url)
    end

    # Lists petition pages in your instance.
    #
    # @param [Int] offset The number of records to skip.
    # @param [Int] limit  The maximum number of results to return.
    def list_petition_pages(offset=0, limit=20)
      target = "#{self.base_url}/petitionpage/"
      options = {
          basic_auth: self.auth,
          query: {
              _limit: limit,
              _offset: offset
          }
      }
      self.class.get(target, options)
    end

    # Find petition pages matching a given name.
    #
    # @param [Int] offset The number of records to skip.
    # @param [Int] limit  The maximum number of results to return.
    # @param [String] name The string to match against name.
    def find_petition_pages(name, limit: 10, offset: 0)
      target = "#{self.base_url}/petitionpage/"

      options = {
          basic_auth: self.auth,
          query: {
            _limit: limit,
            _offset: offset,
            name: name
          }
      }

      self.class.get(target, options)
    end

    # Returns the information for a single PetitionPage.
    #
    # @param [Int] id The ID of the page to return.
    def petition_page(id)
      target = "#{self.base_url}/petitionpage/#{id}/"
      self.class.get(target, {basic_auth: self.auth})
    end

    # Create a petition page in your ActionKit instance.
    #
    # @param [String] name          The name of the page.
    # @param [String] title         The title of the page.
    # @param [URI]    lang          The URI string for the language of this page in the form of /rest/v1/language/{id}
    # @param [URL]    canonical_url The canonical URL for this page.
    def create_petition_page(name, title, lang, canonical_url)
      target = "#{self.base_url}/petitionpage/"
      options = {
          basic_auth: self.auth,
          body: {
            :type => 'petitionpage',
            :hidden => false,
            :name => name,
            :title => title,
            :language => lang,
            :canonical_url => canonical_url
         }.to_json
      }
      self.class.post(target, options)
    end

    # Returns the information for a single ImportPage.
    #
    # @param [Int] id The ID of the page to return.
    def import_page(id)
      target = "#{self.base_url}/importpage/#{id}/"
      response = self.class.get(target, {basic_auth: self.auth})
      JSON.parse(response.body)
    end

    # Create a donation page in your ActionKit instance.
    #
    # @param [String] name          The name of the page.
    # @param [String] title         The title of the page.
    # @param [URI]    lang          The URI string for the language of this page in the form of /rest/v1/language/{id}
    # @param [URL]    canonical_url The canonical URL for this page.
    def create_donation_page(name, title, lang, canonical_url)
      target = "#{self.base_url}/donationpage/"
      options = {
        basic_auth: self.auth,
        body: {
          type:           'donationpage',
          hidden:         false,
          name:           name,
          title:          title,
          language:       lang,
          canonical_url:  canonical_url
        }.to_json
      }
      self.class.post(target, options)
    end



    def parse_action_options(options)
      included_options = {}
      acceptable_options = [
          :ip_address, :is_forwarded, :link,
          :mailing, :referring_mailing, :referring_user,
          :name
      ]
      options.each_key do |key|
        if acceptable_options.include? key.to_sym
          included_options[key.to_sym] = options[key]
        elsif key.to_s.start_with? 'action_'
          # ActionKit allows for custom fields to be entered into an action by prepending
          # their name with 'action_'
          included_options[key.to_sym] = options[key]
        end
      end
      included_options
    end

    def validate_donation_options(options)
      required_base_keys = [:donationpage, :order, :user]
      if required_base_keys.all? {|s| options.key? s}
        options[:donationpage] = validate_donationpage_options(options[:donationpage])
        options[:order] = validate_donation_order_options(options[:order])
        options[:user] = validate_donation_user_options(options[:user])
      else
        raise 'Donation options require donationpage, order and user keys in the base hash.'
      end
      options
    end

    def validate_donationpage_options(options)
      required_base_keys = [:name, :payment_account]
      if required_base_keys.all? {|s| options.key? s}
        options
      else
        raise 'Donation Page options require name and payment_account keys in the hash.'
      end
    end

    def validate_donation_order_options(options)
      required_base_keys = [:amount, :exp_date_month, :exp_date_year]
      if required_base_keys.all? {|s| options.key? s}
        if options[:card_num].nil?
          options[:card_num] = '4111111111111111' # Default placeholder card number.
        end

        if options[:card_code].nil?
          options[:card_code] = '007' # Default AK Card Code.
        end
      else
        raise 'Donation Order options require amount, exp_date_month and exp_date_year keys.'
      end
      options
    end

    def validate_donation_user_options(options)
      required_base_keys = [:email, :country]
      if required_base_keys.all? {|s| options.key? s}
        options
      else
        raise 'Donation User options require email and country keys in the hash.'
      end
    end

    def auth
      {
        username: @username,
        password: @password
      }
    end

    private

    def prep_options(data)
      { basic_auth: auth, body: data.to_json }
    end
  end

  class BatchUpsertUsersError < StandardError; end
end

