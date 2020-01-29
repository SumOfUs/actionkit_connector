module ActionKitConnector
  module REST
    module Transaction

      def update_transaction(id, data)
        self.class.put("/transaction/#{id}/", prep_options(data))
      end
    end
  end
end
