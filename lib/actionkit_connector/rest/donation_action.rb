module ActionKitConnector
  module REST
    module DonationAction

      def get_donation_action(id)
        self.class.get("/donationaction/#{id}", basic_auth)
      end

      def update_donation_action(id, data)
        self.class.put("/donationaction/#{id}/", prep_options(data))
      end

      def delete_donation_action(id)
        self.class.delete("/donationaction/#{id}/", basic_auth)
      end
    end
  end
end
